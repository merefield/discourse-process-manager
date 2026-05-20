# frozen_string_literal: true

module ::ProcessManager
  class ProcessAuditLog < ActiveRecord::Base
    self.table_name = "process_manager_process_audit_logs"
  end
end

# == Schema Information
#
# Table name: process_manager_process_audit_logs
#
#  id                         :bigint           not null, primary key
#  ending_category_name       :string
#  ending_position            :integer
#  ending_process_step_name   :string
#  process_name               :string
#  process_step_option_name   :string
#  process_step_option_slug   :string
#  starting_category_name     :string
#  starting_position          :integer
#  starting_process_step_name :string
#  topic_title                :string
#  username                   :string
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  ending_category_id         :bigint
#  ending_process_step_id     :bigint
#  process_id                 :bigint
#  process_step_option_id     :bigint
#  starting_category_id       :bigint
#  starting_process_step_id   :bigint
#  topic_id                   :bigint
#  user_id                    :bigint
#
