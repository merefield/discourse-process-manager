import DiscourseRoute from "discourse/routes/discourse";

export default class AdminPluginsShowProcessesStepsEdit extends DiscourseRoute {
  async model(params) {
    const allProcessSteps = await this.modelFor(
      "adminPlugins.show.processes.steps"
    );
    const id = parseInt(params.step_id, 10);
    const processStep = allProcessSteps.findBy("id", id);

    const processSteps = await this.store.findAll("process-step", {
      process_id: processStep.process_id,
    });
    processStep.set("processSteps", processSteps.content);
    const process = await this.store.find("process", processStep.process_id);
    processStep.set("process", process);
    return processStep;
  }

  async setupController(controller, model) {
    super.setupController(controller, model);

    const processSteps = await this.store.findAll("process-step", {
      process_id: this.currentModel.process_id,
    });
    controller.set("processSteps", processSteps.content);
  }
}
