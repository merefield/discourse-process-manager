# frozen_string_literal: true
module ProcessManager
  class Stats
    def calculate_daily_stats
      return unless SiteSetting.process_manager_enabled

      current_date = Date.current
      now = Time.zone.now
      counts_by_process_step =
        ::ProcessManager::ProcessState
          .where.not(process_id: nil)
          .where.not(process_step_id: nil)
          .group(:process_id, :process_step_id)
          .count
      records =
        counts_by_process_step.map do |(process_id, process_step_id), count|
          {
            cob_date: current_date,
            process_id: process_id,
            process_step_id: process_step_id,
            count: count,
            created_at: now,
            updated_at: now,
          }
        end

      # This rebuild strategy assumes a single scheduler execution.
      # In standard operation this job should not run concurrently.
      ::ProcessManager::ProcessStat.transaction do
        ::ProcessManager::ProcessStat.where(cob_date: current_date.all_day).delete_all
        ::ProcessManager::ProcessStat.insert_all!(records) if records.present?
      end

      ::Rails.logger.info(
        "Process Daily Stats recorded for #{current_date}: #{records.length} step buckets",
      )
    end
  end
end
