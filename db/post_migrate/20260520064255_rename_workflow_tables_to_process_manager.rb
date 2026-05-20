# frozen_string_literal: true

class RenameWorkflowTablesToProcessManager < ActiveRecord::Migration[8.0]
  TABLE_RENAMES = {
    workflows: :process_manager_processes,
    workflow_steps: :process_manager_process_steps,
    workflow_options: :process_manager_process_options,
    workflow_step_options: :process_manager_process_step_options,
    workflow_states: :process_manager_process_states,
    workflow_stats: :process_manager_process_stats,
    workflow_audit_logs: :process_manager_process_audit_logs,
  }

  COLUMN_RENAMES = {
    process_manager_process_steps: {
      workflow_id: :process_id,
    },
    process_manager_process_step_options: {
      workflow_step_id: :process_step_id,
      workflow_option_id: :process_option_id,
      target_step_id: :target_process_step_id,
    },
    process_manager_process_states: {
      workflow_id: :process_id,
      workflow_step_id: :process_step_id,
    },
    process_manager_process_stats: {
      workflow_id: :process_id,
      workflow_step_id: :process_step_id,
    },
    process_manager_process_audit_logs: {
      workflow_id: :process_id,
      workflow_name: :process_name,
      starting_step_id: :starting_process_step_id,
      starting_step_name: :starting_process_step_name,
      ending_step_id: :ending_process_step_id,
      ending_step_name: :ending_process_step_name,
      step_option_id: :process_step_option_id,
      step_option_name: :process_step_option_name,
      step_option_slug: :process_step_option_slug,
    },
  }

  INDEX_RENAMES = {
    process_manager_process_steps: {
      index_workflow_steps_on_category_id: :idx_pm_process_steps_category_id,
      index_workflow_steps_on_workflow_id: :idx_pm_process_steps_process_id,
    },
    process_manager_process_step_options: {
      index_workflow_step_options_on_workflow_option_id: :idx_pm_step_options_process_option_id,
      index_workflow_step_options_on_workflow_step_id: :idx_pm_step_options_process_step_id,
    },
    process_manager_process_states: {
      index_workflow_states_on_topic_id: :idx_pm_process_states_topic_id,
      index_workflow_states_on_workflow_id: :idx_pm_process_states_process_id,
      index_workflow_states_on_workflow_step_id: :idx_pm_process_states_process_step_id,
      idx_workflow_states_updated_at: :idx_pm_process_states_updated_at,
    },
    process_manager_process_stats: {
      index_workflow_stats_on_workflow_id: :idx_pm_process_stats_process_id,
      index_workflow_stats_on_workflow_step_id: :idx_pm_process_stats_process_step_id,
      idx_workflow_stats_daily_workflow_step_unique:
        :idx_pm_process_stats_daily_process_step_unique,
    },
  }

  def up
    TABLE_RENAMES.each { |old_table, new_table| rename_table_if_present(old_table, new_table) }
    COLUMN_RENAMES.each { |table, columns| rename_columns(table, columns) }
    INDEX_RENAMES.each { |table, indexes| rename_indexes(table, indexes) }
  end

  def down
    INDEX_RENAMES.reverse_each { |table, indexes| rename_indexes(table, indexes.invert) }
    COLUMN_RENAMES.reverse_each { |table, columns| rename_columns(table, columns.invert) }

    TABLE_RENAMES.to_a.reverse_each do |old_table, new_table|
      rename_table_if_present(new_table, old_table)
    end
  end

  private

  def rename_table_if_present(old_table, new_table)
    return if !table_exists?(old_table) || table_exists?(new_table)

    rename_table old_table, new_table
  end

  def rename_columns(table, columns)
    return if !table_exists?(table)

    columns.each do |old_column, new_column|
      next if !column_exists?(table, old_column) || column_exists?(table, new_column)

      rename_column table, old_column, new_column
    end
  end

  def rename_indexes(table, indexes)
    return if !table_exists?(table)

    indexes.each do |old_name, new_name|
      next if !index_name_exists?(table, old_name) || index_name_exists?(table, new_name)

      execute "ALTER INDEX #{quote_table_name(old_name)} RENAME TO #{quote_table_name(new_name)}"
    end
  end
end
