# frozen_string_literal: true
# name: discourse-process-manager
# about: A process management plugin for Discourse
# version: 0.6.0
# authors: Robert Barrow
# contact_emails: robert@pavilion.tech
# url: https://github.com/merefield/discourse-process-manager

gem "event_stream_parser", "1.0.0", { require: false }
gem "ruby-openai", "8.1.0", { require: false }

enabled_site_setting :process_manager_enabled

register_asset "stylesheets/common/process_manager_common.scss"
register_asset "stylesheets/desktop/process_manager_desktop.scss", :desktop
register_asset "stylesheets/mobile/process_manager_mobile.scss", :mobile

module ::ProcessManager
  PLUGIN_NAME = "discourse-process-manager"
end

require_relative "lib/process_manager/engine"

register_svg_icon "right-left" if respond_to?(:register_svg_icon)

after_initialize do
  reloadable_patch do
    ListController.prepend(ProcessManager::ListControllerExtension)
    TopicQuery.prepend(ProcessManager::TopicQueryExtension)
    Topic.prepend(ProcessManager::TopicExtension)
    Notification.singleton_class.prepend(ProcessManager::NotificationExtension)
  end

  register_topic_preloader_associations({ process_state: %i[process process_step] }) do
    SiteSetting.process_manager_enabled
  end

  Discourse::Application.routes.prepend do
    get "/processes/charts" => "list#process_charts", :as => :process_charts
  end

  Discourse.top_menu_items.push(:processes)
  Discourse.anonymous_top_menu_items.push(:processes)
  Discourse.filters.push(:processes)
  Discourse.anonymous_filters.push(:processes)

  SeedFu.fixture_paths << File.join(__dir__, "db", "fixtures")

  add_admin_route(
    "admin.process_manager.title",
    "discourse-process-manager",
    { use_new_show_route: true },
  )

  add_to_class(:category, :process_enabled) do
    ProcessManager::ProcessStep.find_by(category_id: self.id)&.position == 1 || false
  end

  add_to_class(:category, :process_slug) do
    ProcessManager::Process
      .joins(:process_steps)
      .where(process_manager_process_steps: { category_id: self.id })
      .first
      &.slug
  end

  # prevent non-staff from changing category on a process topic
  PostRevisor.track_topic_field(:category_id) do |tc, category_id|
    if tc.guardian.is_staff?
      tc.record_change("category_id", tc.topic.category_id, category_id)
      tc.topic.category_id = category_id
    else
      if ::ProcessManager::ProcessState.find_by(topic_id: tc.topic.id).present?
        # TODO get this to work and add a translation
        tc.topic.errors.add(
          :base,
          :process,
          message: "you can't change category on a process topic unless you are staff",
        )
        next
      else
        tc.record_change("category_id", tc.topic.category_id, category_id)
        tc.topic.category_id = category_id
      end
    end
  end

  add_to_class(:topic, :process_slug) { process_state&.process&.slug }

  add_to_class(:topic, :process_name) { process_state&.process&.name }

  add_to_class(:topic, :process_step_slug) { process_state&.process_step&.slug }

  add_to_class(:topic, :process_step_name) { process_state&.process_step&.name }

  add_to_class(:topic, :process_step_position) { process_state&.process_step&.position }

  add_to_class(:topic, :process_step_options) do
    step = process_state&.process_step
    return [] unless step

    step
      .process_step_options
      .includes(:process_option)
      .order(:position)
      .map { |wso| wso.process_option.slug }
  end

  add_to_class(:topic, :process_step_actions) do
    step = process_state&.process_step
    return [] unless step

    step_options = step.process_step_options.includes(:process_option).order(:position)

    target_steps =
      ProcessManager::ProcessStep.where(
        id: step_options.map(&:target_process_step_id).compact.uniq,
      ).index_by(&:id)

    step_options.map do |process_step_option|
      option = process_step_option.process_option
      target_step = target_steps[process_step_option.target_process_step_id]

      {
        slug: option&.slug,
        option_name: option&.name,
        target_step_name: target_step&.name,
        target_step_position: target_step&.position,
      }
    end
  end

  add_to_class(:topic, :process_step_entered_at) { process_state&.updated_at }

  add_to_class(:topic, :process_overdue_days_threshold) do
    state = process_state
    return nil if state.blank?

    step_overdue_days = state.process_step&.overdue_days
    process_overdue_days = state.process&.overdue_days

    if !step_overdue_days.nil?
      step_overdue_days.to_i
    elsif !process_overdue_days.nil?
      process_overdue_days.to_i
    else
      SiteSetting.process_manager_overdue_days_default.to_i
    end
  end

  add_to_class(:topic, :process_overdue) do
    threshold_days = process_overdue_days_threshold
    return false if threshold_days.blank? || threshold_days <= 0

    entered_at = process_step_entered_at
    return false if entered_at.blank?

    entered_at <= threshold_days.days.ago
  end

  add_to_class(:topic_list, :process_kanban_process) do
    return @process_kanban_process if defined?(@process_kanban_process)

    process_ids = topics.map { |topic| topic.process_state&.process_id }.compact.uniq

    @process_kanban_process =
      if process_ids.length == 1
        ProcessManager::Process.includes(
          process_steps: [
            { category: :parent_category },
            { process_step_options: :process_option },
          ],
        ).find_by(id: process_ids.first)
      end
  end

  add_to_class(:topic_list, :has_process_topics?) do
    return @has_process_topics if defined?(@has_process_topics)

    @has_process_topics = topics.any? { |topic| topic.process_state.present? }
  end

  add_to_class(:topic_list, :process_kanban_compatible) do
    process = process_kanban_process
    process.present? && process.kanban_compatible?
  end

  add_to_class(:topic_list, :process_kanban_show_tags) do
    process = process_kanban_process
    process.present? && process.show_kanban_tags != false
  end

  add_to_class(:topic_list, :process_single_process_id) { process_kanban_process&.id }

  add_to_class(:topic_list, :process_single_process_name) { process_kanban_process&.name }

  add_to_class(:topic_list, :process_kanban_steps) do
    return [] if !process_kanban_compatible

    process_kanban_process
      .process_steps
      .order(:position)
      .map do |step|
        category = step.category
        {
          id: step.id,
          position: step.position,
          name: step.name,
          category_color: category&.color || category&.parent_category&.color,
        }
      end
  end

  add_to_class(:topic_list, :process_kanban_transitions) do
    return [] if !process_kanban_compatible

    process = process_kanban_process
    steps = process.process_steps.to_a
    steps_by_id = steps.index_by(&:id)
    first_option_for_edge = {}

    steps.each do |step|
      step
        .process_step_options
        .sort_by { |option| option.position.to_i }
        .each do |step_option|
          target_step = steps_by_id[step_option.target_process_step_id]
          next if target_step.blank?

          option_slug = step_option.process_option&.slug
          next if option_slug.blank?

          edge_key = [step.position.to_i, target_step.position.to_i]
          first_option_for_edge[edge_key] ||= option_slug
        end
    end

    first_option_for_edge.map do |(from_position, to_position), option_slug|
      { from_position: from_position, to_position: to_position, option_slug: option_slug }
    end
  end

  add_to_serializer(
    :topic_view,
    :process_slug,
    include_condition: -> { object.topic.process_slug.present? },
  ) { object.topic.process_slug }

  add_to_serializer(
    :topic_view,
    :process_name,
    include_condition: -> { object.topic.process_name.present? },
  ) { object.topic.process_name }

  add_to_serializer(
    :topic_view,
    :process_step_slug,
    include_condition: -> { object.topic.process_step_slug.present? },
  ) { object.topic.process_step_slug }

  add_to_serializer(
    :topic_view,
    :process_step_name,
    include_condition: -> { object.topic.process_step_name.present? },
  ) { object.topic.process_step_name }

  add_to_serializer(
    :topic_view,
    :process_step_position,
    include_condition: -> { object.topic.process_step_position.present? },
  ) { object.topic.process_step_position }

  add_to_serializer(
    :topic_view,
    :process_step_options,
    include_condition: -> do
      @process_step_options ||= object.topic.process_step_options
      @process_step_options.present?
    end,
  ) do
    @process_step_options ||= object.topic.process_step_options
    @process_step_options
  end

  add_to_serializer(
    :topic_view,
    :process_step_actions,
    include_condition: -> do
      @process_step_actions ||= object.topic.process_step_actions
      @process_step_actions.present?
    end,
  ) { @process_step_actions ||= object.topic.process_step_actions }

  add_to_serializer(
    :topic_view,
    :process_can_act,
    include_condition: -> { object.topic.process_name.present? },
  ) do
    begin
      scope.ensure_can_create_topic_on_category!(object.topic.category_id)
      true
    rescue Discourse::InvalidAccess
      false
    end
  end

  add_to_serializer(
    :topic_view,
    :process_step_entered_at,
    include_condition: -> { object.topic.process_step_entered_at.present? },
  ) { object.topic.process_step_entered_at }

  add_to_serializer(
    :topic_list_item,
    :process_name,
    include_condition: -> { object.process_name.present? },
  ) { object.process_name }

  add_to_serializer(
    :topic_list_item,
    :process_step_position,
    include_condition: -> { object.process_step_position.present? },
  ) { object.process_step_position.to_i }

  add_to_serializer(
    :topic_list_item,
    :process_step_name,
    include_condition: -> { object.process_step_name.present? },
  ) { object.process_step_name }

  add_to_serializer(
    :topic_list_item,
    :process_overdue,
    include_condition: -> { object.process_name.present? },
  ) { object.process_overdue }

  add_to_serializer(
    :topic_list_item,
    :process_can_act,
    include_condition: -> { object.process_name.present? },
  ) do
    # Cache permission checks per category on the scope to avoid repeated work
    permissions_cache =
      scope.instance_variable_get(:@process_can_act_category_permissions) ||
        scope.instance_variable_set(:@process_can_act_category_permissions, {})

    category_id = object.category_id

    unless permissions_cache.key?(category_id)
      begin
        scope.ensure_can_create_topic_on_category!(category_id)
        permissions_cache[category_id] = true
      rescue Discourse::InvalidAccess
        permissions_cache[category_id] = false
      end
    end

    permissions_cache[category_id]
  end

  add_to_serializer(
    :topic_list,
    :process_kanban_compatible,
    include_condition: -> { object.has_process_topics? },
  ) { object.process_kanban_compatible }

  add_to_serializer(
    :topic_list,
    :process_kanban_process_name,
    include_condition: -> { object.process_single_process_name.present? },
  ) { object.process_kanban_process.name }

  add_to_serializer(
    :topic_list,
    :process_single_process_id,
    include_condition: -> { object.has_process_topics? },
  ) { object.process_single_process_id }

  add_to_serializer(
    :topic_list,
    :process_can_view_charts,
    include_condition: -> { object.has_process_topics? },
  ) { ProcessManager::ChartsPermissions.can_view?(scope.user) }

  add_to_serializer(
    :topic_list,
    :process_kanban_show_tags,
    include_condition: -> { object.has_process_topics? },
  ) { object.process_kanban_show_tags }

  add_to_serializer(
    :topic_list,
    :process_kanban_steps,
    include_condition: -> { object.has_process_topics? },
  ) { object.process_kanban_steps }

  add_to_serializer(
    :topic_list,
    :process_kanban_transitions,
    include_condition: -> { object.has_process_topics? },
  ) { object.process_kanban_transitions }

  on(:topic_created) do |*params|
    topic, opts = params

    if SiteSetting.process_manager_enabled
      process_step =
        ProcessManager::ProcessStep.joins(:process).find_by(
          category_id: topic.category_id,
          position: 1,
          process_manager_processes: {
            enabled: true,
          },
        )
      if process_step
        ProcessManager::ProcessState.create!(
          topic_id: topic.id,
          process_id: process_step.process_id,
          process_step_id: process_step.id,
        )
      end
    end
  end

  on(:post_alerter_after_save_post) do |post, new_record, notified|
    next if !new_record
    ProcessManager::PostNotificationHandler.new(post, notified).handle
  end
end
