# frozen_string_literal: true

class RenameWorkflowTransitionPostActions < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  BATCH_SIZE = 50_000

  def up
    max_id = select_value("SELECT COALESCE(MAX(id), 0) FROM posts").to_i
    lower_id = 0

    while lower_id < max_id
      upper_id = lower_id + BATCH_SIZE

      execute <<~SQL
        UPDATE posts
        SET action_code = 'process_transition'
        WHERE id > #{lower_id}
          AND id <= #{upper_id}
          AND action_code = 'workflow_transition'
      SQL

      lower_id = upper_id
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
