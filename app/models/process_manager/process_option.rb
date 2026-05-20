# frozen_string_literal: true

module ::ProcessManager
  class ProcessOption < ActiveRecord::Base
    self.table_name = "process_manager_process_options"
  end
end

# == Schema Information
#
# Table name: process_manager_process_options
#
#  id         :bigint           not null, primary key
#  name       :string
#  slug       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
