# frozen_string_literal: true

module Jobs
  module ProcessManager
    class AiTransitions < ::Jobs::Scheduled
      sidekiq_options retry: false

      every 1.hour

      def execute(args = {})
        ::ProcessManager::AiActions.new.transition_all
      end
    end
  end
end
