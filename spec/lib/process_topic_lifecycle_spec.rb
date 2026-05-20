# frozen_string_literal: true

require_relative "../plugin_helper"

describe "Process topic lifecycle behavior" do
  fab!(:process) { Fabricate(:process, name: "Disabled Process", enabled: false) }
  fab!(:start_category, :category)
  fab!(:mid_category, :category)
  fab!(:step_1) do
    Fabricate(:process_step, workflow_id: process.id, category_id: start_category.id, position: 1)
  end
  fab!(:step_2) do
    Fabricate(:process_step, workflow_id: process.id, category_id: mid_category.id, position: 2)
  end

  it "does not initialize process_state for topics when process is disabled" do
    SiteSetting.process_manager_enabled = true
    topic = Fabricate(:topic, category: start_category)
    ProcessManager::ProcessState.where(topic_id: topic.id).delete_all

    expect do DiscourseEvent.trigger(:topic_created, topic, {}) end.not_to change {
      ProcessManager::ProcessState.count
    }
  end

  it "allows creating a topic in a later step category when process is disabled" do
    topic = Fabricate.build(:topic, category: mid_category)

    expect(topic).to be_valid
  end
end
