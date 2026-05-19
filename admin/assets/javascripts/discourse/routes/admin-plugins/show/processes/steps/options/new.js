import DiscourseRoute from "discourse/routes/discourse";

export default class AdminPluginsShowProcessesStepOptionsNew extends DiscourseRoute {
  async model() {
    // Get the parent workflow step
    const processStep = this.modelFor(
      "adminPlugins.show.processes.steps.options"
    );
    // Create a new workflow step record
    const record = this.store.createRecord("workflow-step-option", {
      workflow_step_id: processStep.id,
      position:
        processStep.workflow_step_options.length > 0
          ? processStep.workflow_step_options[
              processStep.workflow_step_options.length - 1
            ].position + 1
          : 1,
    });

    // Attach it to the parent workflow to current step
    record.set("processStep", processStep);

    return record;
  }

  async setupController(controller, model) {
    super.setupController(controller, model);

    const processOptions = await this.store.findAll("workflow-option");
    controller.set("processOptions", processOptions.content);
    const processSteps = await this.store.findAll("workflow-step", {
      workflow_id: this.currentModel.processStep.workflow_id,
    });
    controller.set("processSteps", processSteps.content);
  }
}
