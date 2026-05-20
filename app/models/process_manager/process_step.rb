# frozen_string_literal: true

module ::ProcessManager
  class ProcessStep < ActiveRecord::Base
    self.table_name = "process_manager_process_steps"
    belongs_to :process, class_name: "ProcessManager::Process"
    belongs_to :category
    has_many :process_step_options,
             class_name: "ProcessManager::ProcessStepOption",
             foreign_key: :process_step_id
    has_many :process_states,
             class_name: "ProcessManager::ProcessState",
             foreign_key: :process_step_id

    validates :category_id, presence: true
    validates :name, presence: true
    validates :overdue_days,
              numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0,
                allow_nil: true,
              }
  end
end

# == Schema Information
#
# Table name: process_manager_process_steps
#
#  id           :bigint           not null, primary key
#  ai_enabled   :boolean          default(FALSE)
#  ai_prompt    :text
#  description  :text
#  name         :string
#  overdue_days :integer
#  position     :integer
#  slug         :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  category_id  :bigint
#  process_id   :bigint
#
# Indexes
#
#  index_process_manager_process_steps_on_category_id  (category_id)
#  index_process_manager_process_steps_on_process_id   (process_id)
#
# Foreign Keys
#
#  fk_rails_...  (category_id => categories.id)
#  fk_rails_...  (process_id => process_manager_processes.id)
#
