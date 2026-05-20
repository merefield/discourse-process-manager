# frozen_string_literal: true
Fabricator(:process_option, class_name: "ProcessManager::ProcessOption") do
  name { sequence(:name) { |i| "option #{i}" } }
  slug { sequence(:slug) { |i| "option-#{i}" } }
end
