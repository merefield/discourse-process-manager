import RestModel from "discourse/models/rest";

const CREATE_ATTRIBUTES = [
  "workflow_step_id",
  "workflow_option_id",
  "position",
  "target_step_id",
];

export default class ProcessStepOption extends RestModel {
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
    const processStepOption = ProcessStepOption.create(attrs);
    return processStepOption;
  }
}
