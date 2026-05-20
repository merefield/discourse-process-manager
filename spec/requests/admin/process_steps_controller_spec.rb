# frozen_string_literal: true

require_relative "../../plugin_helper"

describe ProcessManager::Admin::ProcessStepsController do
  fab!(:admin)
  fab!(:process) { Fabricate(:process, name: "Process Steps Controller Process") }
  fab!(:category_1, :category)
  fab!(:category_2, :category)
  fab!(:option) { Fabricate(:process_option, slug: "next-step") }
  fab!(:step_1) do
    Fabricate(:process_step, process_id: process.id, category_id: category_1.id, position: 1)
  end
  fab!(:step_2) do
    Fabricate(:process_step, process_id: process.id, category_id: category_2.id, position: 2)
  end
  fab!(:process_step_option_1) do
    Fabricate(
      :process_step_option,
      process_step_id: step_1.id,
      process_option_id: option.id,
      target_process_step_id: step_2.id,
      position: 1,
    )
  end

  before { sign_in(admin) }

  it "does not add per-step queries when listing process steps" do
    get "/admin/plugins/discourse-process-manager/processes/#{process.id}/process_steps.json"
    base_query_count =
      track_sql_queries do
        get "/admin/plugins/discourse-process-manager/processes/#{process.id}/process_steps.json"
        expect(response.status).to eq(200)
      end.count

    5.times do |index|
      extra_category = Fabricate(:category)
      extra_step =
        Fabricate(
          :process_step,
          process_id: process.id,
          category_id: extra_category.id,
          position: index + 3,
        )
      Fabricate(
        :process_step_option,
        process_step_id: extra_step.id,
        process_option_id: option.id,
        target_process_step_id: step_1.id,
        position: 1,
      )
    end

    get "/admin/plugins/discourse-process-manager/processes/#{process.id}/process_steps.json"
    expanded_query_count =
      track_sql_queries do
        get "/admin/plugins/discourse-process-manager/processes/#{process.id}/process_steps.json"
        expect(response.status).to eq(200)
      end.count

    expect(expanded_query_count).to be <= base_query_count + 2
  end

  it "does not include every root category as a visual lane for top-level process steps" do
    unrelated_root_category = Fabricate(:category)
    child_of_process_category = Fabricate(:category, parent_category_id: category_1.id)

    get "/admin/plugins/discourse-process-manager/processes/#{process.id}/process_steps.json"

    category_ids = response.parsed_body["process_categories"].map { |category| category["id"] }

    expect(category_ids).to contain_exactly(category_1.id, category_2.id)
    expect(category_ids).not_to include(unrelated_root_category.id)
    expect(category_ids).not_to include(child_of_process_category.id)
  end

  it "includes sibling subcategory lanes for process steps under a shared parent category" do
    parent_category = Fabricate(:category)
    subcategory_1 = Fabricate(:category, parent_category_id: parent_category.id)
    subcategory_2 = Fabricate(:category, parent_category_id: parent_category.id)
    unused_sibling = Fabricate(:category, parent_category_id: parent_category.id)

    step_1.update!(category_id: subcategory_1.id)
    step_2.update!(category_id: subcategory_2.id)

    get "/admin/plugins/discourse-process-manager/processes/#{process.id}/process_steps.json"

    category_ids = response.parsed_body["process_categories"].map { |category| category["id"] }

    expect(category_ids).to include(subcategory_1.id, subcategory_2.id, unused_sibling.id)
    expect(category_ids).not_to include(parent_category.id)
  end

  it "deletes incoming and outgoing step options when destroying a process step" do
    category_3 = Fabricate(:category)
    step_3 =
      Fabricate(:process_step, process_id: process.id, category_id: category_3.id, position: 3)
    incoming_step_option =
      Fabricate(
        :process_step_option,
        process_step_id: step_2.id,
        process_option_id: option.id,
        target_process_step_id: step_1.id,
        position: 1,
      )
    unrelated_step_option =
      Fabricate(
        :process_step_option,
        process_step_id: step_2.id,
        process_option_id: option.id,
        target_process_step_id: step_3.id,
        position: 2,
      )
    outgoing_process_step_option_id = process_step_option_1.id
    incoming_process_step_option_id = incoming_step_option.id
    unrelated_process_step_option_id = unrelated_step_option.id

    delete "/admin/plugins/discourse-process-manager/process_steps/#{step_1.id}.json"

    expect(response.status).to eq(204)
    expect(ProcessManager::ProcessStep.exists?(step_1.id)).to eq(false)
    expect(ProcessManager::ProcessStepOption.exists?(outgoing_process_step_option_id)).to eq(false)
    expect(ProcessManager::ProcessStepOption.exists?(incoming_process_step_option_id)).to eq(false)
    expect(ProcessManager::ProcessStepOption.exists?(unrelated_process_step_option_id)).to eq(true)
  end

  it "rolls back step option deletion when process step destroy raises" do
    incoming_step_option =
      Fabricate(
        :process_step_option,
        process_step_id: step_2.id,
        process_option_id: option.id,
        target_process_step_id: step_1.id,
        position: 2,
      )

    allow_any_instance_of(ProcessManager::ProcessStep).to receive(
      :destroy!,
    ).and_wrap_original do |method, *args|
      method.receiver.errors.add(:base, "forced failure")
      raise ActiveRecord::RecordNotDestroyed.new("forced failure", method.receiver)
    end

    delete "/admin/plugins/discourse-process-manager/process_steps/#{step_1.id}.json"

    expect(response.status).to eq(422)
    expect(ProcessManager::ProcessStep.exists?(step_1.id)).to eq(true)
    expect(ProcessManager::ProcessStepOption.exists?(process_step_option_1.id)).to eq(true)
    expect(ProcessManager::ProcessStepOption.exists?(incoming_step_option.id)).to eq(true)
  end

  it "reorders a process step and displaced step atomically" do
    put "/admin/plugins/discourse-process-manager/process_steps/#{step_1.id}/reorder.json",
        params: {
          process_step: {
            category_id: category_2.id,
            position: 2,
          },
        }

    expect(response.status).to eq(200)
    expect(step_1.reload.category_id).to eq(category_2.id)
    expect(step_1.position).to eq(2)
    expect(step_2.reload.category_id).to eq(category_2.id)
    expect(step_2.position).to eq(1)
  end

  it "rolls back displaced step position when reorder fails" do
    allow_any_instance_of(ProcessManager::ProcessStep).to receive(
      :update!,
    ).and_wrap_original do |method, *args|
      if method.receiver.id == step_1.id
        method.receiver.errors.add(:base, "forced failure")
        raise ActiveRecord::RecordInvalid.new(method.receiver)
      end

      method.call(*args)
    end

    put "/admin/plugins/discourse-process-manager/process_steps/#{step_1.id}/reorder.json",
        params: {
          process_step: {
            category_id: category_2.id,
            position: 2,
          },
        }

    expect(response.status).to eq(422)
    expect(step_1.reload.category_id).to eq(category_1.id)
    expect(step_1.position).to eq(1)
    expect(step_2.reload.category_id).to eq(category_2.id)
    expect(step_2.position).to eq(2)
  end
end
