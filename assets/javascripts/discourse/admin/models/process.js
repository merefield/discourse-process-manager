import RestModel from "discourse/models/rest";

const CREATE_ATTRIBUTES = [
  "name",
  "description",
  "enabled",
  "overdue_days",
  "show_kanban_tags",
];

export default class Process extends RestModel {
  updateProperties() {
    let attrs = this.getProperties(CREATE_ATTRIBUTES);
    attrs.id = this.id;
    return attrs;
  }

  createProperties() {
    let attrs = this.getProperties(CREATE_ATTRIBUTES);
    return attrs;
  }

  workingCopy() {
    let attrs = this.getProperties(CREATE_ATTRIBUTES);

    const process = Process.create(attrs);
    return process;
  }
}
