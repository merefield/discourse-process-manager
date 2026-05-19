# frozen_string_literal: true
Fabricator(:workflow_state, class_name: "ProcessManager::ProcessState") do
  topic_id { Fabricate(:topic).id }
  workflow_id { Fabricate(:workflow).id }
  workflow_step_id { Fabricate(:workflow_step).id }
end
