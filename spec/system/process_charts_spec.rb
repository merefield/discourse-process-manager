# frozen_string_literal: true

RSpec.describe "Process charts" do
  fab!(:process_discovery_page) { PageObjects::Pages::ProcessDiscovery.new }
  fab!(:admin, :admin)
  fab!(:allowed_group, :group)

  fab!(:process) { Fabricate(:process, name: "Primary Burn Down Process") }
  fab!(:other_process) { Fabricate(:process, name: "Secondary Burn Down Process") }

  fab!(:category_1, :category)
  fab!(:category_2, :category)
  fab!(:category_3, :category)
  fab!(:category_4, :category)
  fab!(:other_category, :category)

  fab!(:step_1) do
    Fabricate(
      :process_step,
      process_id: process.id,
      category_id: category_1.id,
      position: 1,
      name: "Queue",
    )
  end
  fab!(:step_2) do
    Fabricate(
      :process_step,
      process_id: process.id,
      category_id: category_2.id,
      position: 2,
      name: "Review",
    )
  end
  fab!(:step_3) do
    Fabricate(
      :process_step,
      process_id: process.id,
      category_id: category_3.id,
      position: 3,
      name: "Approval",
    )
  end
  fab!(:step_4) do
    Fabricate(
      :process_step,
      process_id: process.id,
      category_id: category_4.id,
      position: 4,
      name: "Done",
    )
  end
  fab!(:other_step) do
    Fabricate(
      :process_step,
      process_id: other_process.id,
      category_id: other_category.id,
      position: 1,
      name: "Other Queue",
    )
  end

  before do
    enable_current_plugin
    SiteSetting.process_manager_enabled = true
    SiteSetting.process_manager_charts_allowed_groups = allowed_group.id.to_s

    10.times do
      topic = Fabricate(:topic, category: category_1)
      Fabricate(
        :process_state,
        topic_id: topic.id,
        process_id: process.id,
        process_step_id: step_1.id,
      )
    end

    create_stats_history_for(process, [step_1, step_2, step_3, step_4])
    create_stats_history_for(other_process, [other_step], base_count: 10)

    sign_in(admin)
  end

  it "renders a burn down chart on /processes/charts with weeks selector" do
    process_discovery_page.visit_process_charts

    expect(page).to have_current_path("/processes/charts", url: false)
    expect(process_discovery_page).to have_process_burndown_chart
    expect(process_discovery_page).to have_process_burndown_chart_canvas
    expect(page).to have_css(".process-burndown__process-name", text: "Process: #{process.name}")
    expect(process_discovery_page).to have_process_view_option("Chart")
    expect(process_discovery_page).to have_process_chart_weeks_selector
    expect(process_discovery_page).to have_no_process_view_option("Kanban")
    expect(process_discovery_page).to have_process_chart_legend_step("Queue")
    expect(process_discovery_page).to have_process_chart_legend_step("Review")
    expect(process_discovery_page).to have_process_chart_legend_step("Approval")
    expect(process_discovery_page).to have_process_chart_legend_step("Done")
    expect(process_discovery_page.process_chart_point_count).to eq(14)
    expect(process_discovery_page).to have_chart_weeks_option(1)
    expect(process_discovery_page).to have_view_then_period_order
  end

  it "updates chart horizon when weeks filter changes up to 12 weeks" do
    process_discovery_page.visit_process_charts

    process_discovery_page.select_chart_weeks(12)

    expect(page).to have_current_path(%r{/processes\?.*chart_weeks=12}, url: true)
    expect(page).to have_current_path(%r{/processes\?.*process_view=chart}, url: true)
    expect(process_discovery_page.process_chart_point_count).to eq(84)
  end

  it "supports a one-week period in chart mode" do
    process_discovery_page.visit_process_charts

    process_discovery_page.select_chart_weeks(1)

    expect(page).to have_current_path(%r{/processes\?.*chart_weeks=1}, url: true)
    expect(process_discovery_page.process_chart_point_count).to eq(7)
  end

  it "supports switching chart mode from process discovery view dropdown" do
    process_discovery_page.visit_processes
    process_discovery_page.select_process_view("Chart")

    expect(page).to have_current_path(%r{/processes\?.*process_view=chart}, url: true)
    expect(process_discovery_page).to have_process_burndown_chart
  end

  def create_stats_history_for(process_record, steps, base_count: nil)
    end_date = Date.current.end_of_week(:saturday)
    start_date = end_date - 13.days
    days = (start_date..end_date).to_a

    days.each_with_index do |day, day_index|
      if steps.length == 1
        Fabricate(
          :process_stat,
          cob_date: day,
          process_id: process_record.id,
          process_step_id: steps.first.id,
          count: base_count || 10,
        )
        next
      end

      queue_count, review_count, approval_count, done_count =
        complex_daily_counts(days.count)[day_index]

      Fabricate(
        :process_stat,
        cob_date: day,
        process_id: process_record.id,
        process_step_id: steps[0].id,
        count: queue_count,
      )
      Fabricate(
        :process_stat,
        cob_date: day,
        process_id: process_record.id,
        process_step_id: steps[1].id,
        count: review_count,
      )
      Fabricate(
        :process_stat,
        cob_date: day,
        process_id: process_record.id,
        process_step_id: steps[2].id,
        count: approval_count,
      )
      Fabricate(
        :process_stat,
        cob_date: day,
        process_id: process_record.id,
        process_step_id: steps[3].id,
        count: done_count,
      )
    end
  end

  def complex_daily_counts(day_count)
    queue = 6
    review = 0
    approval = 0
    done = 0
    delayed_not_started = 4
    delayed_starts = [0, 0, 0, 1, 0, 1, 0, 1, 1, 0, 0, 0, 0, 0]

    Array.new(day_count) do |day_index|
      starts_today = [delayed_starts.fetch(day_index, 0), delayed_not_started].min
      delayed_not_started -= starts_today
      queue += starts_today

      moved_to_review = [queue, day_index.even? ? 2 : 1].min
      queue -= moved_to_review
      review += moved_to_review

      moved_to_approval = [review, day_index % 3 == 0 ? 2 : 1].min
      review -= moved_to_approval
      approval += moved_to_approval

      moved_to_done = [approval, day_index >= 2 ? 1 : 0].min
      approval -= moved_to_done
      done += moved_to_done

      if day_index % 6 == 5 && done > 0
        done -= 1
        review += 1
      end

      [queue, review, approval, done]
    end
  end
end
