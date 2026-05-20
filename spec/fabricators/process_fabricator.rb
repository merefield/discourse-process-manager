# frozen_string_literal: true
Fabricator(:process, class_name: "ProcessManager::Process") do
  name { sequence(:name) { |i| "This is a test process #{i}" } }
  description { sequence(:description) { |i| "This is a test description #{i}" } }
end
