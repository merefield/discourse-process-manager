# frozen_string_literal: true
Fabricator(:process_step_option, class_name: "ProcessManager::ProcessStepOption") do
  workflow_option_id { Fabricate(:process_option).id }
  workflow_step_id { Fabricate(:process_step).id }
  position { sequence(:step_option_position) { |i| i } }
  target_step_id { Fabricate(:process_step).id }
end
