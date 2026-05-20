# frozen_string_literal: true

require_relative "../plugin_helper"

RSpec.describe ProcessManager::ProcessSerializer do
  fab!(:admin)
  fab!(:process) { Fabricate(:process, name: "Warning Process") }
  fab!(:category_1, :category)
  fab!(:category_2, :category)
  fab!(:step_1) do
    Fabricate(
      :process_step,
      workflow_id: process.id,
      category_id: category_1.id,
      position: 1,
      name: "Start",
    )
  end
  fab!(:step_2) do
    Fabricate(
      :process_step,
      workflow_id: process.id,
      category_id: category_2.id,
      position: 1,
      name: "Duplicate Position",
    )
  end
  fab!(:option_with_missing_label) do
    Fabricate(:process_option, slug: "missing_translation_slug", name: "Missing Label")
  end
  fab!(:step_option_with_orphan_target) do
    Fabricate(
      :process_step_option,
      workflow_step_id: step_1.id,
      workflow_option_id: option_with_missing_label.id,
      target_step_id: 999_999,
      position: 1,
    )
  end

  it "exposes admin validation warnings for definition inconsistencies" do
    serializer = described_class.new(process, scope: Guardian.new(admin))

    warnings = serializer.validation_warnings
    warning_codes = warnings.map { |warning| warning[:code] || warning["code"] }

    expect(warning_codes).to include("duplicate_step_positions")
    expect(warning_codes).to include("orphan_target_steps")
    expect(warning_codes).to include("missing_option_labels")
  end
end
