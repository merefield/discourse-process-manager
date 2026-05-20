# frozen_string_literal: true

require_relative "../plugin_helper"

RSpec.describe "Process overdue thresholds", type: :request do
  fab!(:user) { Fabricate(:user, trust_level: TrustLevel[1], refresh_auto_groups: true) }

  fab!(:process_global_default) do
    Fabricate(:process, name: "Global Default Process", overdue_days: nil)
  end
  fab!(:process_override) { Fabricate(:process, name: "Process Override", overdue_days: 5) }
  fab!(:process_step_override) { Fabricate(:process, name: "Step Override", overdue_days: 10) }
  fab!(:process_disabled) { Fabricate(:process, name: "Disabled Overdue", overdue_days: 0) }

  fab!(:category_global_default, :category)
  fab!(:category_process_override, :category)
  fab!(:category_step_override, :category)
  fab!(:category_disabled, :category)

  fab!(:step_global_default) do
    Fabricate(
      :process_step,
      workflow_id: process_global_default.id,
      category_id: category_global_default.id,
      position: 1,
      overdue_days: nil,
    )
  end
  fab!(:step_process_override) do
    Fabricate(
      :process_step,
      workflow_id: process_override.id,
      category_id: category_process_override.id,
      position: 1,
      overdue_days: nil,
    )
  end
  fab!(:step_step_override) do
    Fabricate(
      :process_step,
      workflow_id: process_step_override.id,
      category_id: category_step_override.id,
      position: 1,
      overdue_days: 2,
    )
  end
  fab!(:step_disabled) do
    Fabricate(
      :process_step,
      workflow_id: process_disabled.id,
      category_id: category_disabled.id,
      position: 1,
      overdue_days: nil,
    )
  end

  fab!(:topic_global_default) do
    Fabricate(:topic_with_op, category: category_global_default, user: user)
  end
  fab!(:topic_process_override) do
    Fabricate(:topic_with_op, category: category_process_override, user: user)
  end
  fab!(:topic_step_override) do
    Fabricate(:topic_with_op, category: category_step_override, user: user)
  end
  fab!(:topic_disabled) { Fabricate(:topic_with_op, category: category_disabled, user: user) }

  fab!(:state_global_default) do
    Fabricate(
      :process_state,
      topic_id: topic_global_default.id,
      workflow_id: process_global_default.id,
      workflow_step_id: step_global_default.id,
    )
  end
  fab!(:state_process_override) do
    Fabricate(
      :process_state,
      topic_id: topic_process_override.id,
      workflow_id: process_override.id,
      workflow_step_id: step_process_override.id,
    )
  end
  fab!(:state_step_override) do
    Fabricate(
      :process_state,
      topic_id: topic_step_override.id,
      workflow_id: process_step_override.id,
      workflow_step_id: step_step_override.id,
    )
  end
  fab!(:state_disabled) do
    Fabricate(
      :process_state,
      topic_id: topic_disabled.id,
      workflow_id: process_disabled.id,
      workflow_step_id: step_disabled.id,
    )
  end

  before do
    SiteSetting.process_manager_enabled = true
    SiteSetting.process_manager_overdue_days_default = 3
    sign_in(user)

    [
      category_global_default,
      category_process_override,
      category_step_override,
      category_disabled,
    ].each do |category|
      category.set_permissions(everyone: :full, staff: :full)
      category.save!
    end

    state_global_default.update_columns(updated_at: 4.days.ago)
    state_process_override.update_columns(updated_at: 4.days.ago)
    state_step_override.update_columns(updated_at: 3.days.ago)
    state_disabled.update_columns(updated_at: 30.days.ago)
  end

  it "uses step then process then global overdue thresholds when overdue=1 filter is enabled" do
    get "/processes.json", params: { overdue: "1" }

    topic_ids = response.parsed_body.dig("topic_list", "topics").map { |t| t["id"] }

    expect(topic_ids).to include(topic_global_default.id)
    expect(topic_ids).to include(topic_step_override.id)
    expect(topic_ids).not_to include(topic_process_override.id)
    expect(topic_ids).not_to include(topic_disabled.id)
  end

  it "marks overdue state per topic in process list payload" do
    get "/processes.json"

    topics = response.parsed_body.dig("topic_list", "topics")
    topic_by_id = topics.index_by { |topic| topic["id"] }

    expect(topic_by_id[topic_global_default.id]["process_overdue"]).to eq(true)
    expect(topic_by_id[topic_process_override.id]["process_overdue"]).to eq(false)
    expect(topic_by_id[topic_step_override.id]["process_overdue"]).to eq(true)
    expect(topic_by_id[topic_disabled.id]["process_overdue"]).to eq(false)
  end
end
