# frozen_string_literal: true
Fabricator(:workflow, class_name: "ProcessManager::Process") do
  name { sequence(:name) { |i| "This is a test workflow #{i}" } }
  description { sequence(:description) { |i| "This is a test description #{i}" } }
end
