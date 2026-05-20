# frozen_string_literal: true

RSpec.describe "Process quick filters" do
  fab!(:process_discovery_page) { PageObjects::Pages::ProcessDiscovery.new }
  fab!(:user) { Fabricate(:user, trust_level: TrustLevel[1], refresh_auto_groups: true) }
  fab!(:process) { Fabricate(:process, name: "Quick Filter Process") }
  fab!(:kanban_tag) { Fabricate(:tag, name: "kanban-tag") }
  fab!(:category_1, :category)
  fab!(:category_2, :category)
  fab!(:category_3, :category)
  fab!(:step_1) do
    Fabricate(:process_step, process_id: process.id, category_id: category_1.id, position: 1)
  end
  fab!(:step_2) do
    Fabricate(:process_step, process_id: process.id, category_id: category_2.id, position: 2)
  end
  fab!(:step_3) do
    Fabricate(:process_step, process_id: process.id, category_id: category_3.id, position: 3)
  end
  fab!(:next_option) { Fabricate(:process_option, slug: "next", name: "Next") }
  fab!(:finish_option) { Fabricate(:process_option, slug: "finish", name: "Finish") }
  fab!(:step_transition) do
    Fabricate(
      :process_step_option,
      process_step_id: step_1.id,
      process_option_id: next_option.id,
      target_process_step_id: step_2.id,
    )
  end
  fab!(:step_transition_2) do
    Fabricate(
      :process_step_option,
      process_step_id: step_2.id,
      process_option_id: finish_option.id,
      target_process_step_id: step_3.id,
    )
  end
  fab!(:topic_1) { Fabricate(:topic_with_op, category: category_1, user: user, tags: [kanban_tag]) }
  fab!(:topic_2) { Fabricate(:topic_with_op, category: category_1, user: user) }
  fab!(:process_state_1) do
    Fabricate(
      :process_state,
      topic_id: topic_1.id,
      process_id: process.id,
      process_step_id: step_1.id,
    )
  end
  fab!(:process_state_2) do
    Fabricate(
      :process_state,
      topic_id: topic_2.id,
      process_id: process.id,
      process_step_id: step_2.id,
    )
  end

  before do
    enable_current_plugin
    SiteSetting.process_manager_enabled = true
    SiteSetting.tagging_enabled = true
    category_1.set_permissions(everyone: :full, staff: :full)
    category_2.set_permissions(everyone: :readonly, staff: :full)
    category_3.set_permissions(everyone: :readonly, staff: :full)
    category_1.save!
    category_2.save!
    category_3.save!
    topic_2.update_columns(category_id: category_2.id)
    process_state_1.update_columns(updated_at: 5.days.ago)
    sign_in(user)
  end

  it "filters process topics by step position via process query params" do
    page.visit("/processes?process_step_position=2")

    expect(page).to have_content(topic_2.title)
    expect(page).to have_no_content(topic_1.title)
  end

  it "filters process topics by overdue days via process query params" do
    page.visit("/processes?overdue_days=3")

    expect(page).to have_content(topic_1.title)
    expect(page).to have_no_content(topic_2.title)
  end

  it "filters process topics to categories where the user can create topics" do
    page.visit("/processes?my_categories=1")

    expect(page).to have_content(topic_1.title)
    expect(page).to have_no_content(topic_2.title)
  end

  it "applies my categories from the quick filter controls" do
    process_discovery_page.visit_processes
    expect(process_discovery_page).to have_quick_filters

    process_discovery_page.toggle_my_categories

    expect(page).to have_current_path(%r{/processes\?.*my_categories=1}, url: true)
    expect(page).to have_content(topic_1.title)
    expect(page).to have_no_content(topic_2.title)
  end

  it "applies overdue quick filter from controls" do
    process_discovery_page.visit_processes
    expect(process_discovery_page).to have_quick_filters

    process_discovery_page.toggle_overdue
    expect(page).to have_current_path(%r{/processes\?.*overdue=1}, url: true)
    expect(page).to have_content(topic_1.title)
    expect(page).to have_no_content(topic_2.title)
  end

  it "applies step quick filter from controls" do
    process_discovery_page.visit_processes
    expect(process_discovery_page).to have_quick_filters

    process_discovery_page.set_step_filter(2)
    expect(page).to have_current_path(%r{/processes\?.*process_step_position=2}, url: true)
    expect(page).to have_content(topic_2.title)
    expect(page).to have_no_content(topic_1.title)
    expect(page).to have_css(".process-quick-filters__apply-step.btn-primary")
  end

  it "toggles step quick filter and active state on repeated apply" do
    process_discovery_page.visit_processes
    expect(process_discovery_page).to have_quick_filters
    expect(page).to have_css(".process-quick-filters__apply-step.btn-default")

    process_discovery_page.set_step_filter(2)
    expect(page).to have_current_path(%r{/processes\?.*process_step_position=2}, url: true)
    expect(page).to have_css(".process-quick-filters__apply-step.btn-primary")

    process_discovery_page.set_step_filter(2)
    expect(page).to have_current_path("/processes", url: false)
    expect(page).to have_css(".process-quick-filters__apply-step.btn-default")
  end

  it "does not redirect repeatedly when saved filters contain empty values" do
    page.visit("/")
    page.execute_script(
      "localStorage.setItem('process_manager_quick_filters', JSON.stringify({ my_categories: null, overdue_days: null, process_step_position: '' }))",
    )

    process_discovery_page.visit_processes

    expect(page).to have_current_path("/processes", url: false)
    expect(process_discovery_page).to have_quick_filters
  end

  it "updates filters without a full page reload" do
    process_discovery_page.visit_processes
    page.execute_script("window.__processNoReloadMarker = 'alive'")

    process_discovery_page.toggle_my_categories

    expect(page).to have_current_path(%r{/processes\?.*my_categories=1}, url: true)
    expect(page.evaluate_script("window.__processNoReloadMarker")).to eq("alive")
  end

  it "toggles quick filter button state and query params on repeated click" do
    process_discovery_page.visit_processes

    expect(page).to have_css(".process-quick-filters__my-categories.btn-default")

    process_discovery_page.toggle_my_categories
    expect(page).to have_current_path(%r{/processes\?.*my_categories=1}, url: true)
    expect(page).to have_css(".process-quick-filters__my-categories.btn-primary")

    process_discovery_page.toggle_my_categories
    expect(page).to have_current_path("/processes", url: false)
    expect(page).to have_css(".process-quick-filters__my-categories.btn-default")
  end

  it "shows overdue state in a dedicated process list column" do
    process_discovery_page.visit_processes

    expect(page).to have_css("th.process-overdue-column")
    expect(page).to have_css("tr[data-topic-id='#{topic_1.id}'] .process-overdue-indicator")
    expect(page).to have_no_css("tr[data-topic-id='#{topic_2.id}'] .process-overdue-indicator")
  end

  it "shows kanban toggle only when the current list is a single compatible process" do
    process_discovery_page.visit_processes

    expect(process_discovery_page).to have_process_view_toggle
    expect(process_discovery_page).to have_no_process_view_option("Chart")
  end

  it "toggles between process list and kanban board view" do
    process_discovery_page.visit_processes
    expect(page).to have_css(".topic-list")
    expect(page).to have_no_css(".process-kanban")

    process_discovery_page.toggle_process_view

    expect(page).to have_current_path(%r{/processes\?.*process_view=kanban}, url: true)
    expect(process_discovery_page).to have_kanban_board
    expect(process_discovery_page).to have_kanban_column_for_step(1)
    expect(process_discovery_page).to have_kanban_column_for_step(2)
    expect(process_discovery_page).to have_kanban_column_for_step(3)
    expect(process_discovery_page).to have_kanban_card_for_topic(topic_1.id)
    expect(process_discovery_page).to have_kanban_card_for_topic(topic_2.id)
    expect(page).to have_no_css(".topic-list")
    expect(process_discovery_page.process_view_value).to eq("kanban")

    process_discovery_page.toggle_process_view

    expect(page).to have_current_path("/processes", url: false)
    expect(page).to have_css(".topic-list")
    expect(page).to have_no_css(".process-kanban")
    expect(process_discovery_page.process_view_value).to eq("list")
  end

  it "supports drag-drop transitions with legal and illegal column highlighting" do
    process_discovery_page.visit_processes
    process_discovery_page.toggle_process_view

    expect(process_discovery_page).to have_kanban_card_for_topic_in_step(topic_1.id, 1)
    expect(process_discovery_page).to have_kanban_card_for_topic_in_step(topic_2.id, 2)

    process_discovery_page.start_drag_on_kanban_card(topic_1.id)

    expect(process_discovery_page).to have_kanban_legal_drop_target_for_step(2)
    expect(process_discovery_page).to have_kanban_illegal_drop_target_for_step(3)

    process_discovery_page.end_drag_on_kanban_card(topic_1.id)
    process_discovery_page.drag_kanban_card_to_step(topic_1.id, 3)

    expect(process_discovery_page).to have_kanban_card_for_topic_in_step(topic_1.id, 1)

    process_discovery_page.drag_kanban_card_to_step(topic_1.id, 2)

    expect(process_discovery_page).to have_no_kanban_card_for_topic_in_step(topic_1.id, 1)
    expect(process_discovery_page).to have_kanban_card_for_topic_in_step(topic_1.id, 2)
  end

  it "supports keyboard arrow transitions for focused kanban cards when legal" do
    process_discovery_page.visit_processes
    process_discovery_page.toggle_process_view

    expect(process_discovery_page).to have_kanban_card_for_topic_in_step(topic_1.id, 1)

    process_discovery_page.move_kanban_card_with_key(topic_1.id, "ArrowRight")
    expect(process_discovery_page).to have_kanban_card_for_topic_in_step(topic_1.id, 2)

    process_discovery_page.move_kanban_card_with_key(topic_1.id, "ArrowLeft")
    expect(process_discovery_page).to have_kanban_card_for_topic_in_step(topic_1.id, 2)
  end

  it "uses step category colors for kanban column borders" do
    category_1.update_columns(color: "112233")
    category_2.update_columns(color: "445566")
    category_3.update_columns(color: "778899")

    process_discovery_page.visit_processes
    process_discovery_page.toggle_process_view

    expect(process_discovery_page.kanban_column_border_color(1)).to eq(
      css_rgb_for_hex(category_1.reload.color),
    )
    expect(process_discovery_page.kanban_column_border_color(2)).to eq(
      css_rgb_for_hex(category_2.reload.color),
    )
    expect(process_discovery_page.kanban_column_border_color(3)).to eq(
      css_rgb_for_hex(category_3.reload.color),
    )
  end

  it "refreshes kanban view after stale transition errors to re-sync backend state" do
    process_discovery_page.visit_processes
    process_discovery_page.toggle_process_view

    expect(process_discovery_page).to have_kanban_card_for_topic_in_step(topic_1.id, 1)

    # Simulate another actor advancing this item after the client has loaded.
    process_state_1.update_columns(process_step_id: step_2.id)

    process_discovery_page.drag_kanban_card_to_step(topic_1.id, 2)

    expect(page).to have_css(
      ".dialog-body",
      text:
        "Transition Failed: probably due to stale UI state - please try again after refresh - refreshing!",
    )
    find("#dialog-holder .btn-primary").click
    expect(process_discovery_page).to have_no_kanban_card_for_topic_in_step(topic_1.id, 1)
    expect(process_discovery_page).to have_kanban_card_for_topic_in_step(topic_1.id, 2)
  end

  it "shows kanban card tags when enabled on the process and hides them when disabled" do
    process_discovery_page.visit_processes
    process_discovery_page.toggle_process_view

    expect(process_discovery_page).to have_kanban_tag_for_topic(topic_1.id, "kanban-tag")

    process.update!(show_kanban_tags: false)
    process_discovery_page.visit_processes
    process_discovery_page.toggle_process_view

    expect(process_discovery_page).to have_no_kanban_tag_for_topic(topic_1.id, "kanban-tag")
  end

  it "does not show kanban toggle when the process list includes multiple processes" do
    other_process = Fabricate(:process, name: "Second Process")
    other_step =
      Fabricate(
        :process_step,
        process_id: other_process.id,
        category_id: category_1.id,
        position: 1,
      )
    other_topic = Fabricate(:topic_with_op, category: category_1, user: user)
    Fabricate(
      :process_state,
      topic_id: other_topic.id,
      process_id: other_process.id,
      process_step_id: other_step.id,
    )

    process_discovery_page.visit_processes

    expect(process_discovery_page).to have_no_process_view_toggle
  end

  def css_rgb_for_hex(hex)
    normalized = hex.delete("#")
    normalized =
      normalized.chars.map { |channel| "#{channel}#{channel}" }.join if normalized.length == 3
    red, green, blue = normalized.scan(/../).map { |channel| channel.to_i(16) }
    "rgb(#{red}, #{green}, #{blue})"
  end
end
