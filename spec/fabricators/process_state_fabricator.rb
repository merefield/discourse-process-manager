# frozen_string_literal: true
Fabricator(:process_state, class_name: "ProcessManager::ProcessState") do
  topic_id { Fabricate(:topic).id }
  workflow_id { Fabricate(:process).id }
  workflow_step_id { Fabricate(:process_step).id }
end
