# frozen_string_literal: true

module ProcessManager
  module ListControllerExtension
    extend ActiveSupport::Concern

    prepended do
      before_action :ensure_process_manager_enabled, only: %i[workflow workflow_charts]
      skip_before_action :ensure_logged_in, only: %i[workflow]
    end

    def workflow
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
            .joins(:workflow_step, :workflow)
            .where(
              "COALESCE(workflow_steps.overdue_days, workflows.overdue_days, ?) > 0",
              default_overdue_days,
            )
            .where(
              "workflow_states.updated_at <= NOW() - (COALESCE(workflow_steps.overdue_days, workflows.overdue_days, ?) * INTERVAL '1 day')",
              default_overdue_days,
            )
        process_filters_applied = true
      elsif params[:overdue_days].present? && params[:overdue_days].to_i > 0
        cutoff = params[:overdue_days].to_i.days.ago
        process_topic_ids_scope =
          process_topic_ids_scope.where("workflow_states.updated_at <= ?", cutoff)
        process_filters_applied = true
      end

      if params[:process_step_position].present? && params[:process_step_position].to_i > 0
        process_topic_ids_scope =
          process_topic_ids_scope.joins(:workflow_step).where(
            workflow_steps: {
              position: params[:process_step_position].to_i,
            },
          )
        process_filters_applied = true
      end

      list_opts[:topic_ids] = process_topic_ids_scope if process_filters_applied

      list = TopicQuery.new(user, list_opts).public_send("list_workflow")
      list_query_opts = list_opts.except(:topic_ids)
      list.more_topics_url = url_for(construct_url_with(:next, list_query_opts))
      list.prev_topics_url = url_for(construct_url_with(:prev, list_query_opts))
      respond_with_list(list)
    end

    def workflow_charts
      if !ProcessManager::ChartsPermissions.can_view?(current_user)
        raise Discourse::InvalidAccess.new(
                nil,
                nil,
                custom_message: "discourse_workflow.errors.charts_access_denied",
              )
      end

      workflow
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
