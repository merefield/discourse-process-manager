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
#  id               :bigint           not null, primary key
#  topic_id         :bigint
#  process_id      :bigint
#  process_step_id :bigint
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_process_states_on_topic_id         (topic_id)
#  index_process_states_on_process_id       (process_id)
#  index_process_states_on_process_step_id  (process_step_id)
#  idx_process_states_updated_at            (updated_at)
#
# Foreign Keys
#
#  fk_rails_...  (topic_id => topics.id)
#  fk_rails_...  (process_id => process_manager_processes.id)
#  fk_rails_...  (process_step_id => process_manager_process_steps.id)
#
