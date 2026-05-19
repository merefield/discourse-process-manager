import RestAdapter from "discourse/adapters/rest";

export default class Adapter extends RestAdapter {
  jsonMode = true;

  basePath(store, type, findArgs) {
    if (findArgs && typeof findArgs === "object") {
      return `/admin/plugins/discourse-workflow/processes/${findArgs.workflow_id}/process_steps/${findArgs.workflow_step_id}/`;
    }

    return "/admin/plugins/discourse-workflow/";
  }

  pathFor(store, type, findArgs) {
    return this.appendQueryParams(
      `${this.basePath(store, type, findArgs)}process_step_options`,
      findArgs
    );
  }

  apiNameFor() {
    return "workflow_step_option";
  }
}
