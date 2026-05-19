import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { array, fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { LinkTo } from "@ember/routing";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import DPageSubheader from "discourse/components/d-page-subheader";
import concatClass from "discourse/helpers/concat-class";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { bind } from "discourse/lib/decorators";
import { i18n } from "discourse-i18n";
import ProcessLinkButton from "./process-link-button";
import ProcessStepOptionEditor from "./process-step-option-editor";

export default class ProcessStepOptionsListEditor extends Component {
  @service store;

  @tracked processStepOptions = [];
  @tracked processStepOptionsPresent = false;

  get currentProcessStepOption() {
    return this.args.currentProcessStepOption;
  }

  get newStepOption() {
    return this.store.createRecord("process-step-option", {
      workflow_step_id: this.args.processStep.id,
    });
  }

  @bind
  loadStepOptions() {
    if (!this.args.currentProcessStepOption && this.args.processStep.id) {
      this.store
        .find("process-step-option", {
          workflow_id: this.args.processStep.workflow_id,
          workflow_step_id: this.args.processStep.id,
        })
        .then((options) => {
          this.processStepOptions = options.content;
          this.processStepOptionsPresent =
            options.content.length > 0 ? true : false;
        });
    }
  }

  localizedStepOptionName(stepOption) {
    return i18n(
      `admin.discourse_workflow.workflows.steps.options.actions.${stepOption.workflow_option.slug}`
    );
  }

  convertStepIdToPosition(processSteps, stepOption) {
    if (!processSteps) {
      return;
    }
    return processSteps.find((step) => step.id === stepOption.target_step_id)
      ?.position;
  }

  @action
  moveUp(option) {
    const options = this.processStepOptions;
    if (option.position > 1) {
      const filteredOptions = options.filter(
        (s) => s.position < option.position
      );
      const previousOption =
        filteredOptions.length > 1
          ? filteredOptions.reduce((prev, curr) =>
              prev.position > curr.position ? prev : curr
            )
          : filteredOptions[0] || null;
      const previousPosition = previousOption
        ? previousOption.position
        : option.position - 1;
      if (previousOption) {
        try {
          previousOption.set("position", option.position);
          previousOption.save();
        } catch (err) {
          popupAjaxError(err);
          return;
        }
      }
      try {
        option.set("position", previousPosition);
        option.save();
      } catch (err) {
        popupAjaxError(err);
        return;
      }
    }
    this.processStepOptions = this.processStepOptions.sort(
      (a, b) => a.position - b.position
    );
  }

  @action
  moveDown(option) {
    const options = this.processStepOptions;
    if (option.position < options.length) {
      const filteredOptions = options.filter(
        (s) => s.position > option.position
      );
      const nextOption =
        filteredOptions.length > 1
          ? filteredOptions.reduce((prev, curr) =>
              prev.position < curr.position ? prev : curr
            )
          : filteredOptions[0] || null;
      const nextPosition = nextOption
        ? nextOption.position
        : option.position + 1;
      if (nextOption) {
        try {
          nextOption.set("position", option.position);
          nextOption.save();
        } catch (err) {
          popupAjaxError(err);
          return;
        }
      }
      try {
        option.set("position", nextPosition);
        option.save();
      } catch (err) {
        popupAjaxError(err);
        return;
      }
    }
    this.processStepOptions = this.processStepOptions.sort(
      (a, b) => a.position - b.position
    );
  }

  /* eslint-disable */
  isfirstOption(option, length) {
    return option.position === 1;
  }
  /* eslint-enable */

  islastOption(option, length) {
    return option.position === length;
  }

  <template>
    <section
      class="process-step-list-editor__current admin-detail pull-left"
      {{didInsert this.loadStepOptions}}
    >
      {{#if this.currentProcessStepOption}}
        <ProcessStepOptionEditor
          @currentProcessStepOption={{this.currentProcessStepOption}}
          @processStep={{@processStep}}
          @processSteps={{@processSteps}}
          @processOptions={{@processOptions}}
        />
      {{else}}
        <DPageSubheader
          @titleLabel={{i18n
            "admin.discourse_workflow.workflows.steps.options.title"
          }}
          @descriptionLabel={{i18n
            "admin.discourse_workflow.workflows.steps.description"
          }}
          @learnMoreUrl="https://meta.discourse.org/t/ai-bot-workflows/306099"
        />

        {{#if this.processStepOptionsPresent}}
          <table class="content-list process-step-list-editor d-admin-table">
            <thead>
              <tr>
                <th>{{i18n
                    "admin.discourse_workflow.workflows.steps.options.position"
                  }}</th>
                <th>{{i18n
                    "admin.discourse_workflow.workflows.steps.options.name"
                  }}</th>
                <th>{{i18n
                    "admin.discourse_workflow.workflows.steps.options.target_position"
                  }}</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {{#each this.processStepOptions as |stepOption|}}
                <tr
                  data-workflow-step-option-id={{stepOption.workflow_step_option_id}}
                  class={{concatClass
                    "process-step-option-list__row d-admin-row__content"
                  }}
                >
                  <td class="d-admin-row__overview">
                    <div class="process-step-option-list__position">
                      {{stepOption.position}}
                    </div>
                  </td>
                  <td class="d-admin-row__overview">
                    <div class="process-step-option-list__name">
                      <strong>
                        {{this.localizedStepOptionName stepOption}}
                      </strong>
                    </div>
                  </td>
                  <td class="d-admin-row__overview">
                    <div class="process-step-option-list__target_position">
                      <strong>
                        {{this.convertStepIdToPosition
                          @processSteps
                          stepOption
                        }}
                      </strong>
                    </div>
                  </td>
                  <td class="d-admin-row__overview">
                    <div class="process-step-option-list__actions">
                      {{! this may have more actions }}
                    </div>
                  </td>
                  <td class="d-admin-row__controls">
                    {{#unless
                      (this.isfirstOption
                        stepOption this.processStepOptions.length
                      )
                    }}
                      <DButton
                        class="process-step-option-list-editor__up_arrow"
                        @icon="arrow-up"
                        @title="admin.discourse_workflow.workflows.options.move_up"
                        {{on "click" (fn this.moveUp stepOption)}}
                      />
                    {{/unless}}
                    {{#unless
                      (this.islastOption
                        stepOption this.processStepOptions.length
                      )
                    }}
                      <DButton
                        class="process-step-option-list-editor__down_arrow"
                        @icon="arrow-down"
                        @title="admin.discourse_workflow.workflows.options.move_down"
                        {{on "click" (fn this.moveDown stepOption)}}
                      />
                    {{/unless}}
                    <LinkTo
                      @route="adminPlugins.show.processes.steps.options.edit"
                      @models={{array
                        @processStep.workflow_id
                        @processStep.id
                        stepOption
                      }}
                      class="btn btn-text btn-small"
                    >{{i18n "admin.discourse_workflow.workflows.edit"}}
                    </LinkTo>
                  </td>
                </tr>
              {{/each}}
            </tbody>
          </table>
        {{/if}}
        <ProcessLinkButton
          @route="adminPlugins.show.processes.steps.options.new"
          @label="admin.discourse_workflow.workflows.steps.options.new"
          @model={{@processStep}}
        />
      {{/if}}
    </section>
  </template>
}
