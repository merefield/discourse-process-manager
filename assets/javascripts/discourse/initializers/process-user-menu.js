import getURL from "discourse/lib/get-url";
import { withPluginApi } from "discourse/lib/plugin-api";
import { formatUsername } from "discourse/lib/utilities";
import { i18n } from "discourse-i18n";

export default {
  name: "process-user-menu",
  initialize() {
    withPluginApi((api) => {
      if (api.registerNotificationTypeRenderer) {
        api.registerNotificationTypeRenderer(
          "process_topic_arrival",
          (NotificationItemBase) => {
            return class extends NotificationItemBase {
              icon = "right-left";
              linkTitle = i18n("notifications.titles.process_topic_arrival", {
                username: formatUsername(this.notification.data.username),
                topic_title: this.notification.data.topic_title,
                process_name: this.notification.data.process_name,
                process_step_name: this.notification.data.process_step_name,
              });
              description = i18n(
                "notifications.process_topic_arrival_description",
                {
                  username: formatUsername(this.notification.data.username),
                  topic_title: this.notification.data.topic_title,
                  process_name: this.notification.data.process_name,
                  process_step_name: this.notification.data.process_step_name,
                }
              );

              get label() {
                const data = this.notification.data;

                return i18n("notifications.process_topic_arrival_label", {
                  username: formatUsername(data.username),
                  topic_title: data.topic_title,
                  process_name: data.process_name,
                  process_step_name: data.process_step_name,
                });
              }

              get linkHref() {
                const data = this.notification.data;
                return getURL(`/t/${data.topic_id}`);
              }
            };
          }
        );
      }

      if (api.registerUserMenuTab) {
        api.registerUserMenuTab((UserMenuTab) => {
          return class extends UserMenuTab {
            get id() {
              return "process-notifications";
            }

            get panelComponent() {
              return "user-menu/process-notifications-list";
            }

            get icon() {
              return "right-left";
            }

            get count() {
              return this.getUnreadCountForType("process_topic_arrival");
            }

            get notificationTypes() {
              return ["process_topic_arrival"];
            }
          };
        });
      }
    });
  },
};
