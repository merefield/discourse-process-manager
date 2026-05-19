import DiscourseRoute from "discourse/routes/discourse";

export default class AdminPluginsShowProcessesStepsEdit extends DiscourseRoute {
  async model(params) {
    const allProcessSteps = await this.modelFor(
      "adminPlugins.show.processes.steps"
    );
    const id = parseInt(params.step_id, 10);
    const processStep = allProcessSteps.findBy("id", id);

    const processSteps = await this.store.findAll("workflow-step", {
      workflow_id: processStep.workflow_id,
    });
    processStep.set("processSteps", processSteps.content);
    const workflow = await this.store.find("workflow", processStep.workflow_id);
    processStep.set("workflow", workflow);
    return processStep;
  }

  async setupController(controller, model) {
    super.setupController(controller, model);

    const processSteps = await this.store.findAll("workflow-step", {
      workflow_id: this.currentModel.workflow_id,
    });
    controller.set("processSteps", processSteps.content);
  }
}
