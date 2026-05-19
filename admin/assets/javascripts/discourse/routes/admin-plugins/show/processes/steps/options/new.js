import DiscourseRoute from "discourse/routes/discourse";

export default class AdminPluginsShowProcessesStepOptionsNew extends DiscourseRoute {
  async model() {
    // Get the parent process step
    const processStep = this.modelFor(
      "adminPlugins.show.processes.steps.options"
    );
    // Create a new process step record
    const record = this.store.createRecord("process-step-option", {
      process_step_id: processStep.id,
      position:
        processStep.process_step_options.length > 0
          ? processStep.process_step_options[
              processStep.process_step_options.length - 1
            ].position + 1
          : 1,
    });

    // Attach it to the parent process to current step
    record.set("processStep", processStep);

    return record;
  }

  async setupController(controller, model) {
    super.setupController(controller, model);

    const processOptions = await this.store.findAll("process-option");
    controller.set("processOptions", processOptions.content);
    const processSteps = await this.store.findAll("process-step", {
      process_id: this.currentModel.processStep.process_id,
    });
    controller.set("processSteps", processSteps.content);
  }
}
