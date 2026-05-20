# frozen_string_literal: true

module ::ProcessManager
  class ProcessStepOption < ActiveRecord::Base
    self.table_name = "process_manager_process_step_options"
    belongs_to :process_step, class_name: "ProcessManager::ProcessStep"
    belongs_to :process_option, class_name: "ProcessManager::ProcessOption"
  end
end

# == Schema Information
#
# Table name: process_manager_process_step_options
#
#  id                 :bigint           not null, primary key
#  position           :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  target_process_step_id :bigint
#  process_option_id      :bigint
#  process_step_id        :bigint
#
# Indexes
#
#  index_process_step_options_on_process_option_id  (process_option_id)
#  index_process_step_options_on_process_step_id    (process_step_id)
#
# Foreign Keys
#
#  fk_rails_...  (process_option_id => process_manager_process_options.id)
#  fk_rails_...  (process_step_id => process_manager_process_steps.id)
#
