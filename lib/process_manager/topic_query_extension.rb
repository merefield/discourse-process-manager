# frozen_string_literal: true

module ProcessManager
  module TopicQueryExtension
    def list_processes
      create_list(:processes) do |topics|
        topics.joins(
          "INNER JOIN workflow_states
                              ON workflow_states.topic_id = topics.id
                      INNER JOIN workflows
                              ON workflows.id = workflow_states.workflow_id",
        )
      end
    end
  end
end
