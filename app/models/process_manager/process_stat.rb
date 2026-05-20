# frozen_string_literal: true

module ::ProcessManager
  class ProcessStat < ActiveRecord::Base
    self.table_name = "process_manager_process_stats"
    belongs_to :process, class_name: "ProcessManager::Process"
    belongs_to :process_step, class_name: "ProcessManager::ProcessStep"
    validates :cob_date, presence: true
    validates :process_id, presence: true
    validates :process_step_id, presence: true
    validates :count,
              presence: true,
              numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0,
              }
  end
end

# == Schema Information
#
# Table name: process_manager_process_stats
#
#  id               :bigint           not null, primary key
#  cob_date         :datetime
#  count            :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  process_id      :bigint
#  process_step_id :bigint
#
# Indexes
#
#  idx_pm_stats_daily_process_step_unique  (cob_date,process_id,process_step_id) UNIQUE
#  index_process_stats_on_process_id       (process_id)
#  index_process_stats_on_process_step_id  (process_step_id)
#
# Foreign Keys
#
#  fk_rails_...  (process_id => process_manager_processes.id)
#  fk_rails_...  (process_step_id => process_manager_process_steps.id)
#
