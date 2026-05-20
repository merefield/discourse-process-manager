# frozen_string_literal: true

module ProcessManager
  class Transition
    def transition(actor, topic, option)
      success = false

      process_state =
        ProcessManager::ProcessState.includes(
          { process: { process_steps: :category } },
          { process_step: { process_step_options: :process_option } },
        ).find_by(topic_id: topic.id)

      return false unless process_state && topic

      current_step = process_state.process_step
      return false unless current_step

      process_step_option_by_slug =
        current_step.process_step_options.index_by do |process_step_option|
          process_step_option.process_option&.slug
        end
      process_step_option = process_step_option_by_slug[option]
      return false if process_step_option.blank?

      target_step =
        process_state.process.process_steps.find do |process_step|
          process_step.id == process_step_option.target_process_step_id
        end
      return false if target_step.blank?

      user_id, username = resolve_actor(actor)

      starting_process_step_id = current_step.id
      starting_process_step_name = current_step.name
      starting_position = current_step.position
      starting_category_id = topic.category_id
      starting_category_name = topic.category&.name
      ending_category_name = target_step.category&.name

      ProcessManager::ProcessState.transaction do
        process_step_option_id = process_step_option.id
        process_step_option_name = process_step_option.process_option.name
        process_step_option_slug = process_step_option.process_option.slug

        # move topic + process state
        topic.update!(category_id: target_step.category_id)
        process_state.update!(process_step_id: target_step.id)

        ProcessManager::ProcessAuditLog.create!(
          user_id: user_id,
          username: username,
          topic_id: topic.id,
          topic_title: topic.title,
          process_id: process_state.process_id,
          process_name: process_state.process.name,
          starting_process_step_id: starting_process_step_id,
          starting_process_step_name: starting_process_step_name,
          ending_process_step_id: process_state.process_step_id,
          ending_process_step_name: target_step.name,
          starting_category_id: starting_category_id,
          starting_category_name: starting_category_name,
          ending_category_id: topic.category_id,
          ending_category_name: ending_category_name,
          starting_position: starting_position,
          ending_position: target_step.position,
          process_step_option_id: process_step_option_id,
          process_step_option_name: process_step_option_name,
          process_step_option_slug: process_step_option_slug,
        )

        Post.create!(
          user_id: user_id,
          topic_id: topic.id,
          raw:
            I18n.t(
              "process_manager.topic_transition_action_description",
              starting_process_step_name: starting_process_step_name,
              ending_process_step_name: target_step.name,
              username: username,
              process_step_option_name: process_step_option_name,
            ),
          post_type: Post.types[:small_action],
          action_code: "process_transition",
        )

        success = true
      end

      if success && topic.category_id != starting_category_id
        ::Jobs::ProcessManager::TopicArrivalNotifier.perform_async({ topic_id: topic.id }.as_json)
      end

      success
    end

    private

    def resolve_actor(actor)
      if actor.is_a?(::User)
        [actor.id, actor.username]
      elsif actor.present?
        user_id = actor.to_i
        username = ::User.where(id: user_id).pick(:username)
        raise ActiveRecord::RecordNotFound if username.blank?
        [user_id, username]
      else
        [-1, "system"]
      end
    end
  end
end
