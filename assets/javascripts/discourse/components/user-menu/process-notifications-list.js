import UserMenuNotificationsList from "discourse/components/user-menu/notifications-list";

export default class UserMenuProcessNotificationsList extends UserMenuNotificationsList {
  get dismissTypes() {
    return this.filterByTypes;
  }

  get emptyStateComponent() {
    return "user-menu/process-notifications-list-empty-state";
  }
}
