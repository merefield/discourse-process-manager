# frozen_string_literal: true

require_relative "../../plugin_helper"
require Rails.root.join(
          "plugins/discourse-process-manager/db/migrate/20260520123325_rename_workflow_transition_post_actions",
        )

RSpec.describe RenameWorkflowTransitionPostActions do
  before do
    @original_verbose = ActiveRecord::Migration.verbose
    ActiveRecord::Migration.verbose = false
  end

  after { ActiveRecord::Migration.verbose = @original_verbose }

  it "renames legacy process transition small action codes" do
    legacy_post =
      Fabricate(:post, post_type: Post.types[:small_action], action_code: "workflow_transition")
    current_post =
      Fabricate(:post, post_type: Post.types[:small_action], action_code: "process_transition")
    unrelated_post =
      Fabricate(:post, post_type: Post.types[:small_action], action_code: "closed.enabled")

    described_class.new.up

    expect(legacy_post.reload.action_code).to eq("process_transition")
    expect(current_post.reload.action_code).to eq("process_transition")
    expect(unrelated_post.reload.action_code).to eq("closed.enabled")
  end
end
