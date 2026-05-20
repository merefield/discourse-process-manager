# frozen_string_literal: true

module ::ProcessManager
  class ProcessState < ActiveRecord::Base
    self.table_name = "process_manager_process_states"

    belongs_to :topic
    belongs_to :process, class_name: "ProcessManager::Process"
    belongs_to :process_step, class_name: "ProcessManager::ProcessStep"
  end
end

# == Schema Information
#
# Table name: process_manager_process_states
#
#  id              :bigint           not null, primary key
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  process_id      :bigint
#  process_step_id :bigint
#  topic_id        :bigint
#
# Indexes
#
#  idx_pm_process_states_updated_at                         (updated_at)
#  index_process_manager_process_states_on_process_id       (process_id)
#  index_process_manager_process_states_on_process_step_id  (process_step_id)
#  index_process_manager_process_states_on_topic_id         (topic_id)
#
# Foreign Keys
#
#  fk_rails_...  (process_id => process_manager_processes.id)
#  fk_rails_...  (process_step_id => process_manager_process_steps.id)
#  fk_rails_...  (topic_id => topics.id)
#
