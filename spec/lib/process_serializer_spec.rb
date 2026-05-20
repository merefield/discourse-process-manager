# frozen_string_literal: true

require_relative "../plugin_helper"

describe ProcessManager::ProcessSerializer do
  fab!(:admin)
  fab!(:process) { Fabricate(:process, name: "Serializer Process") }
  fab!(:category_1, :category)
  fab!(:category_2, :category)
  fab!(:step_1) do
    Fabricate(:process_step, process_id: process.id, category_id: category_1.id, position: 1)
  end
  fab!(:step_2) do
    Fabricate(:process_step, process_id: process.id, category_id: category_2.id, position: 2)
  end

  it "serializes process step count and boundary categories from process_steps" do
    serializer = described_class.new(process, scope: Guardian.new(admin))

    expect(serializer.process_steps_count).to eq(2)
    expect(serializer.starting_category_id).to eq(category_1.id)
    expect(serializer.final_category_id).to eq(category_2.id)
    expect(serializer.kanban_compatible).to eq(false)
    expect(serializer.show_kanban_tags).to eq(true)
  end

  it "serializes kanban compatibility when the process graph is compatible" do
    option = Fabricate(:process_option, slug: "next", name: "Next")
    Fabricate(
      :process_step_option,
      process_step_id: step_1.id,
      process_option_id: option.id,
      target_process_step_id: step_2.id,
    )

    serializer = described_class.new(process, scope: Guardian.new(admin))

    expect(serializer.kanban_compatible).to eq(true)
  end
end
