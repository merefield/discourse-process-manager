# frozen_string_literal: true

require_relative "../plugin_helper"

RSpec.describe "Process topic view", type: :request do
  fab!(:user) { Fabricate(:user, trust_level: TrustLevel[1], refresh_auto_groups: true) }
  fab!(:process) { Fabricate(:process, name: "Topic View Process") }
  fab!(:category, :category)
  fab!(:step_1) do
    Fabricate(
      :process_step,
      workflow_id: process.id,
      category_id: category.id,
      position: 1,
      name: "Triage",
    )
  end
  fab!(:option_accept) { Fabricate(:process_option, slug: "accept", name: "Accept") }
  fab!(:step_option) do
    Fabricate(
      :process_step_option,
      workflow_step_id: step_1.id,
      workflow_option_id: option_accept.id,
      position: 1,
    )
  end
  fab!(:topic) { Fabricate(:topic, category: category, user: user) }
  fab!(:process_state) do
    Fabricate(
      :process_state,
      topic_id: topic.id,
      workflow_id: process.id,
      workflow_step_id: step_1.id,
    )
  end

  before do
    SiteSetting.process_manager_enabled = true
    category.set_permissions(everyone: :full, staff: :full)
    category.save!
    sign_in(user)
  end

  it "returns process metadata in topic view json" do
    get "#{topic.relative_url}.json"

    expect(response.status).to eq(200)
    expect(response.parsed_body["process_name"]).to eq(process.name)
    expect(response.parsed_body["process_step_name"]).to eq(step_1.name)
    expect(response.parsed_body["process_step_actions"]).to be_present
  end
end
