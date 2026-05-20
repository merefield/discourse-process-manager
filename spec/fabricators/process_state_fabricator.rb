# frozen_string_literal: true
Fabricator(:process_state, class_name: "ProcessManager::ProcessState") do
  topic_id { Fabricate(:topic).id }
  process_id { Fabricate(:process).id }
  process_step_id { Fabricate(:process_step).id }
end
