# frozen_string_literal: true

require_relative "../../plugin_helper"

describe ProcessManager::Admin::ProcessStepOptionsController do
  fab!(:admin)
  fab!(:process) { Fabricate(:process, name: "Controller Process") }
  fab!(:category_1, :category)
  fab!(:category_2, :category)
  fab!(:step_1) do
    Fabricate(:process_step, process_id: process.id, category_id: category_1.id, position: 1)
  end
  fab!(:step_2) do
    Fabricate(:process_step, process_id: process.id, category_id: category_2.id, position: 2)
  end
  fab!(:existing_option) { Fabricate(:process_option, slug: "start") }
  fab!(:new_option) { Fabricate(:process_option, slug: "next") }
  fab!(:step_option) do
    Fabricate(
      :process_step_option,
      process_step_id: step_1.id,
      process_option_id: existing_option.id,
      target_process_step_id: step_2.id,
      position: 1,
    )
  end

  before { sign_in(admin) }

  it "creates a step option with next position when position is omitted" do
    expect do
      post "/admin/plugins/discourse-process-manager/process_step_options.json",
           params: {
             process_step_option: {
               process_step_id: step_1.id,
               process_option_id: new_option.id,
               target_process_step_id: step_2.id,
             },
           }
    end.to change { ProcessManager::ProcessStepOption.count }.by(1)

    expect(response.status).to eq(201)
    expect(ProcessManager::ProcessStepOption.order(:id).last.position).to eq(2)
  end

  it "updates the process option used by a step option" do
    put "/admin/plugins/discourse-process-manager/process_step_options/#{step_option.id}.json",
        params: {
          process_step_option: {
            process_step_id: step_1.id,
            process_option_id: new_option.id,
            target_process_step_id: step_2.id,
            position: step_option.position,
          },
        }

    expect(response.status).to eq(200)
    expect(step_option.reload.process_option_id).to eq(new_option.id)
  end

  it "does not add per-option queries when listing step options" do
    get "/admin/plugins/discourse-process-manager/processes/#{process.id}/process_steps/#{step_1.id}/process_step_options.json"
    base_query_count =
      track_sql_queries do
        get "/admin/plugins/discourse-process-manager/processes/#{process.id}/process_steps/#{step_1.id}/process_step_options.json"
        expect(response.status).to eq(200)
      end.count

    extra_option = Fabricate(:process_option, slug: "branch")
    Fabricate(
      :process_step_option,
      process_step_id: step_1.id,
      process_option_id: extra_option.id,
      target_process_step_id: step_2.id,
      position: 2,
    )

    get "/admin/plugins/discourse-process-manager/processes/#{process.id}/process_steps/#{step_1.id}/process_step_options.json"
    expanded_query_count =
      track_sql_queries do
        get "/admin/plugins/discourse-process-manager/processes/#{process.id}/process_steps/#{step_1.id}/process_step_options.json"
        expect(response.status).to eq(200)
      end.count

    expect(expanded_query_count).to eq(base_query_count)
  end
end
