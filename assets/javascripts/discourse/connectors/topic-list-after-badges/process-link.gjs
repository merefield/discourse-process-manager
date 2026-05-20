import Component from "@glimmer/component";
import { i18n } from "discourse-i18n";
import ProcessNameLink from "../../components/process-name-link";

export default class ProcessLink extends Component {
  get label() {
    return i18n("process_manager.process_link", {
      process_name: this.args.outletArgs.topic.process_name,
      process_step_name: this.args.outletArgs.topic.process_step_name,
    });
  }

  <template>
    {{#if @outletArgs.topic.process_name}}
      <span class="process-after-title">
        <ProcessNameLink
          @topic_id={{@outletArgs.topic.id}}
          @process_name={{@outletArgs.topic.process_name}}
          @label={{this.label}}
          @icon="right-left"
        />
      </span>
    {{/if}}
  </template>
}
