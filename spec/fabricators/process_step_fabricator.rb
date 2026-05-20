# frozen_string_literal: true
Fabricator(:process_step, class_name: "ProcessManager::ProcessStep") do
  name { sequence(:name) { |i| "This is a test process step #{i}" } }
  workflow_id { Fabricate(:process).id }
  description { sequence(:description) { |i| "This is a test process step description #{i}" } }
  category_id { Fabricate(:category).id }
  position { sequence(:step_position) { |i| i } }
end
