# frozen_string_literal: true

module ProcessManager
  module TopicExtension
    extend ActiveSupport::Concern

    prepended do
      has_one :process_state, class_name: "ProcessManager::ProcessState", foreign_key: :topic_id

      validates_with NotMidwayValidator, on: :create
    end

    def is_process_topic?
      process_state.present?
    end
  end
end
