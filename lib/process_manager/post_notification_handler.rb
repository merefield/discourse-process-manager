# frozen_string_literal: true

##
# Handles :post_alerter_after_save_post events from
# core. Used for notifying users that their chat message
# has been quoted in a post.
module ProcessManager
  WATCHING_FIRST_POST = 4

  class PostNotificationHandler
    attr_reader :post

    def initialize(post, notified_users)
      @post = post
      @notified_users = notified_users
    end

    def handle
      return false if post.post_type == Post.types[:whisper]
      return false if post.topic.blank?
      return false if post.topic.private_message?
      return false if !post.topic.is_process_topic?
      return false if !post.is_first_post?

      process_state = ProcessManager::ProcessState.find_by(topic_id: post.topic.id)
      return false if process_state.blank?

      data = {
        topic_id: post.topic_id,
        user_id: post.user.id,
        username: post.user.username,
        process_name: process_state.process.name,
        process_step_name: process_state.process_step.name,
        topic_title: post.topic.title,
      }

      ::CategoryUser
        .where(notification_level: WATCHING_FIRST_POST, category_id: post.topic.category_id)
        .each do |category_user|
          ::Notification.create!(
            user_id: category_user.user_id,
            notification_type: ::Notification.types[:process_topic_arrival],
            high_priority: true,
            data: data.to_json,
          )
        end
    end
  end
end
