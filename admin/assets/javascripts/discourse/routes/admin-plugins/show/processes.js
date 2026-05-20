import DiscourseRoute from "discourse/routes/discourse";
import { i18n } from "discourse-i18n";

export default class AdminPluginsShowProcesses extends DiscourseRoute {
  async model() {
    return this.store.findAll("process");
  }

  titleToken() {
    return i18n("admin.process_manager.processes.title");
  }
}
