import RestModel from "discourse/models/rest";

const CREATE_ATTRIBUTES = [
  "process_step_id",
  "process_option_id",
  "position",
  "target_process_step_id",
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
