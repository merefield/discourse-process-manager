import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import bodyClass from "discourse/helpers/body-class";
import { i18n } from "discourse-i18n";
import ProcessButtons from "./process-buttons";
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

  get stepAgeLabel() {
    if (!this.args.process_step_entered_at) {
      return null;
    }

    const enteredAt = new Date(this.args.process_step_entered_at);
    const elapsedMs = Date.now() - enteredAt.getTime();
    const elapsedDays = Math.floor(elapsedMs / (1000 * 60 * 60 * 24));

    if (elapsedDays < 1) {
      return i18n("discourse_workflow.topic_banner.step_age_less_than_day");
    }

    return i18n("discourse_workflow.topic_banner.step_age_days", {
      count: elapsedDays,
    });
  }

  <template>
    {{#if @process_name}}
      {{bodyClass "process-topic"}}
      <div class="process-topic-banner">
        <div class="process-banner-border-title">{{i18n
            "discourse_workflow.topic_banner.title"
          }}</div>
        <div class="process-banner-meta">
          <div class="process-banner-section process-process-name">
            <div class="process-banner-title process-process-name-title">{{i18n
                "discourse_workflow.topic_banner.process_title"
              }}</div>
            <div class="process-process-name-name">{{@process_name}}</div>
          </div>
          <div class="process-banner-section process-step-name">
            <div class="process-banner-title process-step-name-title">{{i18n
                "discourse_workflow.topic_banner.step_title"
              }}</div>
            <div class="process-step-name">{{i18n
                "discourse_workflow.topic_banner.step"
                process_step_position=@process_step_position
                process_step_name=@process_step_name
              }}</div>
            {{#if this.stepAgeLabel}}
              <div class="process-step-age-badge">{{this.stepAgeLabel}}</div>
            {{/if}}
          </div>
          <div class="process-banner-section process-step-actions">
            {{#if @process_step_actions}}
              <ProcessButtons
                @process_step_actions={{@process_step_actions}}
                @process_can_act={{@process_can_act}}
                @topic_id={{@topic_id}}
                @category_id={{@category_id}}
              />
            {{/if}}
            {{#unless @process_can_act}}
              <div class="process-actions-blocked-reason">{{i18n
                  "discourse_workflow.topic_banner.blocked_reason_create_permission"
                }}</div>
            {{/unless}}
          </div>
          <div class="process-action-button">
            <DButton
              class="btn-primary"
              @icon="right-left"
              @action={{this.showVisualisationModal}}
              @label="discourse_workflow.topic_banner.visualisation_button"
            />
          </div>
        </div>
      </div>
    {{/if}}
  </template>
}
