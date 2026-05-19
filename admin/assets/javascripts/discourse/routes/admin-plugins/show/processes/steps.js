import DiscourseRoute from "discourse/routes/discourse";
import { i18n } from "discourse-i18n";

export default class AdminPluginsShowProcessesSteps extends DiscourseRoute {
  async model(params) {
    const allProcessSteps = await this.store.findAll("workflow-step", {
      workflow_id: params.workflow_id,
    }); // this.modelFor("adminPlugins.show.processes");
    return allProcessSteps.content;
  }

  titleToken() {
    return i18n("admin.discourse_workflow.workflows.title");
  }
}
