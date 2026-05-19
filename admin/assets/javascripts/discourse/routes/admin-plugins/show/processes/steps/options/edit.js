import DiscourseRoute from "discourse/routes/discourse";

export default class AdminPluginsShowProcessesStepOptionsEdit extends DiscourseRoute {
  async model(params) {
    const allProcessStepOptions = await this.modelFor(
      "adminPlugins.show.processes.steps.options"
    );
    const id = parseInt(params.option_id, 10);
    const processStepOption = allProcessStepOptions.findBy("id", id);
    return processStepOption;
  }

  async setupController(controller, model) {
    super.setupController(controller, model);

    const processOptions = await this.store.findAll("workflow-option");
    controller.set("processOptions", processOptions.content);

    const workflow_id = model.workflow_id;
    const processSteps = await this.store.findAll("workflow-step", {
      workflow_id,
    });
    const stepCollection = processSteps.content || processSteps;
    controller.set("processSteps", stepCollection);

    const processStep = stepCollection.find((step) => {
      return Number(step.id) === Number(model.workflow_step_id);
    });
    controller.set("processStep", processStep);
  }
}
