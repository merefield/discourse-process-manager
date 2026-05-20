import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import { ajax } from "discourse/lib/ajax";
import { extractError } from "discourse/lib/ajax-error";
import { i18n } from "discourse-i18n";

export default class ProcessButtonsComponent extends Component {
  @service dialog;
  @service router;

  @tracked transitioningOption = null;

  processActionLabel = (processAction) => {
    return `process_manager.options.${processAction.slug}.button_label`;
  };

  processActionHelperText = (processAction) => {
    if (!processAction.target_step_name) {
      return null;
    }

    return i18n("process_manager.topic_banner.transition_target", {
      target_step_name: processAction.target_step_name,
    });
  };

  get actionsDisabled() {
    return !this.args.process_can_act || this.transitioningOption !== null;
  }

  @action
  actOnProcess(processAction) {
    const option = processAction.slug;
    if (!option) {
      return;
    }

    const message = i18n(`process_manager.options.${option}.confirmation`);
    const targetSuffix = this.processActionHelperText(processAction);
    const confirmationMessage =
      targetSuffix && message ? `${message} ${targetSuffix}` : message;

    this.dialog.yesNoConfirm({
      message: confirmationMessage,
      didConfirm: () => {
        this.transitioningOption = option;
        ajax(`/discourse-process-manager/act/${this.args.topic_id}`, {
          type: "POST",
          data: { option },
        })
          .then(() => {
            this.router.transitionTo("/c/" + this.args.category_id);
          })
          .catch(async (err) => {
            this.transitioningOption = null;
            await this.dialog.alert(extractError(err));
            this.router.refresh();
          });
      },
    });
  }

  <template>
    <div class="process-banner-title process-buttons-title">
      {{i18n "process_manager.topic_banner.actions_intro"}}
    </div>
    <div class="process-action-buttons">
      {{#each @process_step_actions as |processAction|}}
        <div class="process-action-button">
          <DButton
            class="btn-primary"
            @action={{fn this.actOnProcess processAction}}
            @label={{this.processActionLabel processAction}}
            @disabled={{this.actionsDisabled}}
          />
          {{#if (this.processActionHelperText processAction)}}
            <div class="process-action-helper">{{this.processActionHelperText
                processAction
              }}</div>
          {{/if}}
        </div>
      {{/each}}
    </div>
  </template>
}
