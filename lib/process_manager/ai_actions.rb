# frozen_string_literal: true

module ProcessManager
  class AiActions
    def transition_all
      ProcessManager::ProcessState
        .includes(topic: :first_post, process_step: { process_step_options: :process_option })
        .find_each do |process_state|
          step = process_state.process_step
          next unless step

          # skip if AI not enabled or no options
          next unless step.ai_enabled
          next if step.process_step_options.empty?

          ai_transition(process_state)
        end
    end

    def ai_transition(process_state)
      step = process_state.process_step
      topic = process_state.topic
      return unless step && topic

      client = OpenAI::Client.new(access_token: SiteSetting.process_manager_openai_api_key)
      model_name = SiteSetting.process_manager_ai_model
      system_prompt = SiteSetting.process_manager_ai_prompt_system
      base_user_prompt = step.ai_prompt

      return if base_user_prompt.blank?

      # get option slugs for this step
      options = step.process_step_options.map { |o| o.process_option&.slug }.compact

      return if options.empty?

      user_prompt = base_user_prompt.gsub(/{{options}}/, options.join(", "))
      user_prompt = user_prompt.gsub(/{{topic}}/, topic.first_post.raw)

      messages = [
        { role: "system", content: system_prompt },
        { role: "user", content: user_prompt },
      ]

      response =
        client.chat(
          parameters: {
            model: model_name,
            messages: messages,
            max_tokens: 8,
            temperature: 0.1,
          },
        )

      if response["error"]
        begin
          raise StandardError, response["error"]["message"]
        rescue => e
          Rails.logger.error("Process: There was a problem: #{e}")
        end
        return
      end

      result = response.dig("choices", 0, "message", "content")
      result = result.strip.chomp(".").downcase if result.present?

      Transition.new.transition(nil, topic, result) if result.present? && options.include?(result)
    end
  end
end
