import Component from "@glimmer/component";
import { i18n } from "discourse-i18n";
import ProcessNameLink from "../../components/process-name-link";

export default class ProcessLink extends Component {
  get label() {
    return i18n("discourse_workflow.workflow_link", {
      workflow_name: this.args.outletArgs.topic.workflow_name,
      workflow_step_name: this.args.outletArgs.topic.workflow_step_name,
    });
  }

  <template>
    {{#if @outletArgs.topic.workflow_name}}
      <span class="process-after-title">
        <ProcessNameLink
          @topic_id={{@outletArgs.topic.id}}
          @workflow_name={{@outletArgs.topic.workflow_name}}
          @label={{this.label}}
          @icon="right-left"
        />
      </span>
    {{/if}}
  </template>
}
