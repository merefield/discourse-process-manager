# frozen_string_literal: true

module ProcessManager
  module ListControllerExtension
    extend ActiveSupport::Concern

    prepended do
      before_action :ensure_process_manager_enabled, only: %i[processes process_charts]
      skip_before_action :ensure_logged_in, only: %i[processes]
    end

    def processes
      list_opts = build_topic_list_options
      user = process_list_user
      process_topic_ids_scope = ProcessManager::ProcessState.all.select(:topic_id).distinct
      process_filters_applied = false

      if user.present? && params[:my_categories] == "1"
        allowed_category_ids = Category.topic_create_allowed(Guardian.new(user)).select(:id)
        process_topic_ids_scope =
          process_topic_ids_scope.joins(:topic).where(topics: { category_id: allowed_category_ids })
        process_filters_applied = true
      end

      if params[:overdue] == "1"
        default_overdue_days = SiteSetting.process_manager_overdue_days_default.to_i
        process_topic_ids_scope =
          process_topic_ids_scope
            .joins(:process_step, :process)
            .where(
              "COALESCE(process_manager_process_steps.overdue_days, process_manager_processes.overdue_days, ?) > 0",
              default_overdue_days,
            )
            .where(
              "process_manager_process_states.updated_at <= NOW() - (COALESCE(process_manager_process_steps.overdue_days, process_manager_processes.overdue_days, ?) * INTERVAL '1 day')",
              default_overdue_days,
            )
        process_filters_applied = true
      elsif params[:overdue_days].present? && params[:overdue_days].to_i > 0
        cutoff = params[:overdue_days].to_i.days.ago
        process_topic_ids_scope =
          process_topic_ids_scope.where("process_manager_process_states.updated_at <= ?", cutoff)
        process_filters_applied = true
      end

      if params[:process_step_position].present? && params[:process_step_position].to_i > 0
        process_topic_ids_scope =
          process_topic_ids_scope.joins(:process_step).where(
            process_manager_process_steps: {
              position: params[:process_step_position].to_i,
            },
          )
        process_filters_applied = true
      end

      list_opts[:topic_ids] = process_topic_ids_scope if process_filters_applied

      list = TopicQuery.new(user, list_opts).public_send("list_processes")
      list_query_opts = list_opts.except(:topic_ids)
      list.more_topics_url = url_for(construct_url_with(:next, list_query_opts))
      list.prev_topics_url = url_for(construct_url_with(:prev, list_query_opts))
      respond_with_list(list)
    end

    def process_charts
      if !ProcessManager::ChartsPermissions.can_view?(current_user)
        raise Discourse::InvalidAccess.new(
                nil,
                nil,
                custom_message: "process_manager.errors.charts_access_denied",
              )
      end

      processes
    end

    protected

    def process_list_user
      if respond_to?(:list_target_user, true)
        send(:list_target_user) || current_user
      else
        current_user
      end
    end

    def ensure_process_manager_enabled
      raise Discourse::NotFound if !SiteSetting.process_manager_enabled
    end
  end
end
