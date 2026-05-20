import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import ProcessVisualisationModal from "./process-visualisation-modal";

export default class ProcessButtonsComponent extends Component {
  @service modal;

  @action
  showVisualisationModal() {
    this.modal.show(ProcessVisualisationModal, {
      model: {
        topic_id: this.args.topic_id,
        process_name: this.args.process_name,
      },
    });
  }

  <template>
    <div class="process-action-button">
      <DButton
        class="btn-transparent"
        @action={{this.showVisualisationModal}}
        @icon={{@icon}}
      >
        {{@label}}
      </DButton>
    </div>
  </template>
}
