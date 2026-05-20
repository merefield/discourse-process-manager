# frozen_string_literal: true

module ProcessManager
  module NotificationExtension
    extend ActiveSupport::Concern

    def types
      super.merge(
        process_topic_arrival: 1001, # Add a new notification type
      )
    end
  end
end
