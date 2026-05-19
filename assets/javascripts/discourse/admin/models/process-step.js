import { ajax } from "discourse/lib/ajax";
import RestModel from "discourse/models/rest";

const CREATE_ATTRIBUTES = [
  "workflow_id",
  "position",
  "name",
  "category_id",
  "description",
  "overdue_days",
  "ai_enabled",
  "ai_prompt",
];

export default class ProcessStep extends RestModel {
  static async findAllForProcess(processId) {
    const result = await ajax(
      `discourse_workflow/workflow/${processId}/workflow_step.json`
    );
    return result.workflow_steps;
  }

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
    const processStep = ProcessStep.create(attrs);
    return processStep;
  }
}
