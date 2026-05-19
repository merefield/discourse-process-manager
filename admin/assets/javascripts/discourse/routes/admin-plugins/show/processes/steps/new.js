import DiscourseRoute from "discourse/routes/discourse";

export default class AdminPluginsShowProcessesStepsNew extends DiscourseRoute {
  queryParams = {
    category_id: {
      refreshModel: true,
    },
  };

  async model(params) {
    // Get the parent process
    const process = this.modelFor("adminPlugins.show.processes.steps");

    const sortedSteps = [...process.process_steps].sort(
      (a, b) => a.position - b.position
    );

    // Create a new process step record
    // Asign a default position to be the last existing step + 1
    const record = this.store.createRecord("process-step", {
      process_id: process.id,
      category_id: params.category_id ? parseInt(params.category_id, 10) : null,
      position:
        sortedSteps.length > 0
          ? sortedSteps[process.process_steps.length - 1].position + 1
          : 1,
    });

    // Attach it to the parent process to current step
    record.set("process", process);

    return record;
  }
}
