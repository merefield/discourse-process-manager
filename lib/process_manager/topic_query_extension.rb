# frozen_string_literal: true

module ProcessManager
  module TopicQueryExtension
    def list_processes
      create_list(:processes) do |topics|
        topics.joins(
          "INNER JOIN process_manager_process_states
                              ON process_manager_process_states.topic_id = topics.id
                      INNER JOIN process_manager_processes
                              ON process_manager_processes.id = process_manager_process_states.process_id",
        )
      end
    end
  end
end
