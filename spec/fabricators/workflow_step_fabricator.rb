# frozen_string_literal: true
Fabricator(:workflow_step, class_name: "ProcessManager::ProcessStep") do
  name { sequence(:name) { |i| "This is a test workflow step #{i}" } }
  workflow_id { Fabricate(:workflow).id }
  description { sequence(:description) { |i| "This is a test workflow step description #{i}" } }
  category_id { Fabricate(:category).id }
  position { sequence(:step_position) { |i| i } }
end
