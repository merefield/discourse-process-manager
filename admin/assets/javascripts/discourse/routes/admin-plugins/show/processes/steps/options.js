import DiscourseRoute from "discourse/routes/discourse";
import { i18n } from "discourse-i18n";

export default class AdminPluginsShowProcessesStepOptions extends DiscourseRoute {
  async model(params) {
    const processSteps = this.modelFor("adminPlugins.show.processes.steps");
    const id = parseInt(params.step_id, 10);
    const processStep = processSteps.findBy("id", id);
    const workflow_id = processStep.workflow_id;
    const allProcessStepOptions = await this.store.findAll(
      "process-step-option",
      { workflow_step_id: processStep.id, workflow_id }
    ); // this.modelFor("adminPlugins.show.processes");
    return allProcessStepOptions.content;
  }

  titleToken() {
    return i18n("admin.discourse_workflow.workflows.title");
  }
}
