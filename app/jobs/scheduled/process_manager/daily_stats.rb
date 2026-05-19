# frozen_string_literal: true

module Jobs
  module ProcessManager
    class DailyStats < ::Jobs::Scheduled
      sidekiq_options retry: false

      every 24.hours

      def execute(args = {})
        ::ProcessManager::Stats.new.calculate_daily_stats
      end
    end
  end
end
