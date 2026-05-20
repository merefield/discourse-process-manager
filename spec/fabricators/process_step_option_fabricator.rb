# frozen_string_literal: true
Fabricator(:process_step_option, class_name: "ProcessManager::ProcessStepOption") do
  process_option_id { Fabricate(:process_option).id }
  process_step_id { Fabricate(:process_step).id }
  position { sequence(:process_step_option_position) { |i| i } }
  target_process_step_id { Fabricate(:process_step).id }
end
