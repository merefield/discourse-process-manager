import RestAdapter from "discourse/adapters/rest";

export default class Adapter extends RestAdapter {
  jsonMode = true;

  basePath() {
    return "/admin/plugins/discourse-process-manager/";
  }

  pathFor(store, type, findArgs) {
    return this.appendQueryParams(`${this.basePath()}processes`, findArgs);
  }

  apiNameFor() {
    return "process";
  }
}
