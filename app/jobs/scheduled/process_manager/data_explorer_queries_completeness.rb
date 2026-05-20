# frozen_string_literal: true

module Jobs
  module ProcessManager
    class DataExplorerQueriesCompleteness < ::Jobs::Scheduled
      sidekiq_options retry: false

      every 24.hours

      def execute(args = {})
        if !ActiveRecord::Base.connection.table_exists?(:data_explorer_queries)
          Rails.logger.warn "Skipping DataExplorerQueriesCompleteness: doesn't look like Data Explorer plugin is properly installed"
          return
        end

        if !::DiscourseDataExplorer::Query.exists?(name: "Process Stats (default)")
          query_sql = <<~SQL
        -- [params]
        -- int :process_id = 1
        -- int :num_of_days_history = 14

        SELECT cob_date as "COB DATE",
            w.name as "Process",
            wstp.name as "Step",
            wstt.count as "Count"
        FROM process_manager_process_stats wstt
        INNER JOIN process_manager_process_steps wstp ON wstt.process_step_id = wstp.id
        INNER JOIN process_manager_processes w ON wstt.process_id = w.id
        WHERE wstt.cob_date >= NOW() - (:num_of_days_history * INTERVAL '1 day')
          AND wstt.process_id = :process_id
      SQL

          DB.exec <<~SQL, now: Time.zone.now, query_sql: query_sql
        INSERT INTO data_explorer_queries(name, description, sql, created_at, updated_at)
        VALUES
        ('Process Stats (default)',
        'Daily counts for each process step in a process (useful for e.g. burndown/burnup charts)',
        :query_sql,
        :now,
        :now)
      SQL
        end

        if !::DiscourseDataExplorer::Query.exists?(name: "Process Audit Log (default)")
          query_sql = <<~SQL
        -- [params]
        -- int :process_id = 1
        -- int :num_of_days_history = 14

        SELECT user_id,
            topic_id,
            process_name,
            starting_process_step_name,
            process_step_option_name
        FROM
            process_manager_process_audit_logs
        WHERE created_at >= NOW() - (:num_of_days_history * INTERVAL '1 day')
        AND process_id = :process_id
      SQL

          DB.exec <<~SQL, now: Time.zone.now, query_sql: query_sql
        INSERT INTO data_explorer_queries(name, description, sql, created_at, updated_at)
        VALUES
        ('Process Audit Log (default)',
        'Audit log for process actions',
        :query_sql,
        :now,
        :now)
      SQL
        end
      end
    end
  end
end
