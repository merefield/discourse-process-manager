# frozen_string_literal: true

require_relative "../../../plugin_helper"

RSpec.describe Jobs::ProcessManager::AiTransitions do
  let(:job) { described_class.new }

  it "delegates scheduled execution to AI workflow transitions" do
    ai_actions = instance_spy(ProcessManager::AiActions)
    allow(ProcessManager::AiActions).to receive(:new).and_return(ai_actions)

    job.execute({})

    expect(ProcessManager::AiActions).to have_received(:new)
    expect(ai_actions).to have_received(:transition_all)
  end
end
