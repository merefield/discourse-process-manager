import Component from "@glimmer/component";
import DModal from "discourse/components/d-modal";
import { i18n } from "discourse-i18n";
import ProcessVisualisation from "./process-visualisation";

export default class ProcessVisualisationModalComponent extends Component {
  get title() {
    return i18n("discourse_workflow.topic_banner.visualisation_title", {
      workflow_name: this.args.model.workflow_name,
    });
  }

  <template>
    <DModal
      @title={{this.title}}
      @closeModal={{@closeModal}}
      class="process-visualisation-modal"
    >
      <ProcessVisualisation @model={{@model}} />
    </DModal>
  </template>
}
