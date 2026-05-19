import DiscourseRoute from "discourse/routes/discourse";

export default class AdminPluginsShowProcessesEdit extends DiscourseRoute {
  queryParams = {
    refresh: { refreshModel: true },
  };

  async model(params) {
    const id = parseInt(params.workflow_id, 10);
    return this.store.find("process", id, { reload: true });
  }

  setupController(controller, model) {
    super.setupController(controller, model);
    controller.set(
      "allProcesses",
      this.modelFor("adminPlugins.show.processes")
    );
  }
}
