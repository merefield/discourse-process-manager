# frozen_string_literal: true

require_relative "../plugin_helper"

describe ProcessManager::Process do
  it "keeps slug stable when updating non-name attributes" do
    process = Fabricate(:process, name: "Stable Slug Process")
    original_slug = process.slug

    process.update!(description: "updated description")

    expect(process.reload.slug).to eq(original_slug)
  end

  it "is kanban compatible for a connected process" do
    process = Fabricate(:process, name: "Kanban Compatible")
    step_1 = Fabricate(:process_step, workflow_id: process.id, position: 1)
    step_2 = Fabricate(:process_step, workflow_id: process.id, position: 2)
    option = Fabricate(:process_option, slug: "next")
    Fabricate(
      :process_step_option,
      workflow_step_id: step_1.id,
      workflow_option_id: option.id,
      target_step_id: step_2.id,
    )

    expect(process.kanban_compatible?).to eq(true)
  end

  it "is kanban compatible when there is a cycle through backward transitions" do
    process = Fabricate(:process, name: "Kanban Cycle")
    step_1 = Fabricate(:process_step, workflow_id: process.id, position: 1)
    step_2 = Fabricate(:process_step, workflow_id: process.id, position: 2)
    option_1 = Fabricate(:process_option, slug: "next")
    option_2 = Fabricate(:process_option, slug: "back")
    Fabricate(
      :process_step_option,
      workflow_step_id: step_1.id,
      workflow_option_id: option_1.id,
      target_step_id: step_2.id,
    )
    Fabricate(
      :process_step_option,
      workflow_step_id: step_2.id,
      workflow_option_id: option_2.id,
      target_step_id: step_1.id,
    )

    expect(process.kanban_compatible?).to eq(true)
  end

  it "is not kanban compatible when a directed edge has multiple options" do
    process = Fabricate(:process, name: "Kanban Duplicate Directed Edge")
    step_1 = Fabricate(:process_step, workflow_id: process.id, position: 1)
    step_2 = Fabricate(:process_step, workflow_id: process.id, position: 2)
    option_1 = Fabricate(:process_option, slug: "next")
    option_2 = Fabricate(:process_option, slug: "skip")

    Fabricate(
      :process_step_option,
      workflow_step_id: step_1.id,
      workflow_option_id: option_1.id,
      target_step_id: step_2.id,
    )
    Fabricate(
      :process_step_option,
      workflow_step_id: step_1.id,
      workflow_option_id: option_2.id,
      target_step_id: step_2.id,
    )

    expect(process.kanban_compatible?).to eq(false)
  end

  it "is not kanban compatible when steps are disconnected from start" do
    process = Fabricate(:process, name: "Kanban Disconnected")
    Fabricate(:process_step, workflow_id: process.id, position: 1)
    Fabricate(:process_step, workflow_id: process.id, position: 2)

    expect(process.kanban_compatible?).to eq(false)
  end
end
