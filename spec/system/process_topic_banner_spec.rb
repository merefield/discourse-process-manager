# frozen_string_literal: true

RSpec.describe "Process topic banner" do
  let(:dialog) { PageObjects::Components::Dialog.new }
  let(:process_topic_page) { PageObjects::Pages::ProcessTopic.new }

  fab!(:admin)
  fab!(:actor, :user)
  fab!(:viewer, :user)
  fab!(:actor_group, :group)
  fab!(:process) { Fabricate(:process, name: "Topic Banner Process") }
  fab!(:start_category, :category)
  fab!(:next_category, :category)
  fab!(:step_1) do
    Fabricate(
      :process_step,
      process_id: process.id,
      category_id: start_category.id,
      position: 1,
      name: "Triage",
    )
  end
  fab!(:step_2) do
    Fabricate(
      :process_step,
      process_id: process.id,
      category_id: next_category.id,
      position: 2,
      name: "Review",
    )
  end
  fab!(:option_accept) { Fabricate(:process_option, slug: "accept", name: "Accept") }
  fab!(:step_option) do
    Fabricate(
      :process_step_option,
      process_step_id: step_1.id,
      process_option_id: option_accept.id,
      target_process_step_id: step_2.id,
      position: 1,
    )
  end
  fab!(:topic) { Fabricate(:topic_with_op, category: start_category, user: actor) }
  fab!(:process_state) do
    Fabricate(
      :process_state,
      topic_id: topic.id,
      process_id: process.id,
      process_step_id: step_1.id,
    )
  end

  before do
    enable_current_plugin
    SiteSetting.process_manager_enabled = true
    GroupUser.create!(group_id: actor_group.id, user_id: actor.id)

    start_category.set_permissions(:everyone => :readonly, actor_group.id => :full, :staff => :full)
    next_category.set_permissions(:everyone => :readonly, actor_group.id => :full, :staff => :full)
    start_category.save!
    next_category.save!
  end

  it "exposes transition target metadata on the topic model" do
    sign_in(actor)
    page.visit(topic.relative_url)

    actions =
      page.evaluate_script(
        "Discourse.__container__.lookup('controller:topic').model.process_step_actions",
      )

    expect(actions.first["target_step_name"]).to eq(step_2.name)
  end

  it "exposes transition permission state for users without category topic-create access" do
    sign_in(viewer)
    page.visit(topic.relative_url)

    can_act =
      page.evaluate_script(
        "Discourse.__container__.lookup('controller:topic').model.process_can_act",
      )

    expect(can_act).to eq(false)
  end

  it "exposes when the current process step was entered" do
    process_state.update_columns(updated_at: 3.days.ago)
    sign_in(actor)
    page.visit(topic.relative_url)

    entered_at =
      page.evaluate_script(
        "Discourse.__container__.lookup('controller:topic').model.process_step_entered_at",
      )

    expect(Time.zone.parse(entered_at)).to be < 2.days.ago
  end

  it "returns to process discovery after a topic action" do
    sign_in(admin)
    process_topic_page.visit_topic(topic).click_process_action("Accept")
    dialog.click_yes

    expect(page).to have_current_path("/processes", url: false)
    expect(process_state.reload.process_step_id).to eq(step_2.id)
  end
end
