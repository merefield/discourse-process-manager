import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { array, fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { LinkTo } from "@ember/routing";
import { service } from "@ember/service";
import DBreadcrumbsItem from "discourse/components/d-breadcrumbs-item";
import DButton from "discourse/components/d-button";
import DPageSubheader from "discourse/components/d-page-subheader";
import DToggleSwitch from "discourse/components/d-toggle-switch";
import categoryLink from "discourse/helpers/category-link";
import concatClass from "discourse/helpers/concat-class";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { bind } from "discourse/lib/decorators";
import { i18n } from "discourse-i18n";
import ProcessLinkButton from "./process-link-button";
import ProcessStepEditor from "./process-step-editor";

export default class ProcessStepsListEditor extends Component {
  @service adminPluginNavManager;
  @service store;

  @tracked processSteps = [];
  @tracked processStepsPresent = false;

  get currentProcessStep() {
    return this.args.currentProcessStep;
  }

  get newStep() {
    return this.store.createRecord("process-step", {
      workflow_id: this.args.workflow.id,
    });
  }

  @action
  async toggleAiEnabled(step) {
    const oldValue = step.ai_enabled;
    const newValue = !oldValue;

    try {
      step.set("ai_enabled", newValue);
      await step.save();
    } catch (err) {
      step.set("ai_enabled", oldValue);
      popupAjaxError(err);
    }
  }

  @bind
  loadSteps() {
    if (!this.args.currentProcessStep && this.args.workflow.id) {
      this.store
        .find("process-step", { workflow_id: this.args.workflow.id })
        .then((steps) => {
          this.processSteps = steps.content;
          this.processStepsPresent = steps.content.length > 0 ? true : false;
        });
    }
  }

  @action
  moveUp(step) {
    const steps = this.processSteps;
    if (step.position > 1) {
      const filteredSteps = steps.filter((s) => s.position < step.position);
      const previousStep =
        filteredSteps.length > 1
          ? filteredSteps.reduce((prev, curr) =>
              prev.position > curr.position ? prev : curr
            )
          : filteredSteps[0] || null;
      const previousPosition = previousStep
        ? previousStep.position
        : step.position - 1;
      if (previousStep) {
        try {
          previousStep.set("position", step.position);
          previousStep.save();
        } catch (err) {
          popupAjaxError(err);
          return;
        }
      }
      try {
        step.set("position", previousPosition);
        step.save();
      } catch (err) {
        popupAjaxError(err);
        return;
      }
    }
    this.processSteps = this.processSteps.sort(
      (a, b) => a.position - b.position
    );
  }

  @action
  moveDown(step) {
    const steps = this.processSteps;
    if (step.position < steps.length) {
      const filteredSteps = steps.filter((s) => s.position > step.position);
      const nextStep =
        filteredSteps.length > 1
          ? filteredSteps.reduce((prev, curr) =>
              prev.position < curr.position ? prev : curr
            )
          : filteredSteps[0] || null;
      const nextPosition = nextStep ? nextStep.position : step.position + 1;
      if (nextStep) {
        try {
          nextStep.set("position", step.position);
          nextStep.save();
        } catch (err) {
          popupAjaxError(err);
          return;
        }
      }
      try {
        step.set("position", nextPosition);
        step.save();
      } catch (err) {
        popupAjaxError(err);
        return;
      }
    }
    this.processSteps = this.processSteps.sort(
      (a, b) => a.position - b.position
    );
  }
  /* eslint-disable */
  isfirstStep(step, length) {
    return step.position === 1;
  }
  /* eslint-enable */

  islastStep(step, length) {
    return step.position === length;
  }

  <template>
    <DBreadcrumbsItem
      @path="/admin/plugins/{{this.adminPluginNavManager.currentPlugin.name}}/workflows/steps"
      @label={{i18n "admin.discourse_workflow.workflows.steps.short_title"}}
    />
    <section
      class="process-step-list-editor__current admin-detail pull-left"
      {{didInsert this.loadSteps}}
    >
      {{#if this.currentProcessStep}}
        <ProcessStepEditor
          @currentProcessStep={{this.currentProcessStep}}
          @workflow={{@workflow}}
          @processSteps={{@processSteps}}
        />
      {{else}}
        <DPageSubheader
          @titleLabel={{i18n "admin.discourse_workflow.workflows.steps.title"}}
          @descriptionLabel={{i18n
            "admin.discourse_workflow.workflows.steps.description"
          }}
          @learnMoreUrl="https://meta.discourse.org/t/ai-bot-workflows/306099"
        />

        {{#if this.processStepsPresent}}
          <table class="content-list process-step-list-editor d-admin-table">
            <thead>
              <tr>
                <th>{{i18n
                    "admin.discourse_workflow.workflows.steps.position"
                  }}</th>
                <th>{{i18n
                    "admin.discourse_workflow.workflows.steps.name"
                  }}</th>
                <th>{{i18n
                    "admin.discourse_workflow.workflows.steps.category"
                  }}</th>
                <th>{{i18n
                    "admin.discourse_workflow.workflows.steps.description"
                  }}</th>
                <th>{{i18n
                    "admin.discourse_workflow.workflows.steps.ai_enabled"
                  }}</th>
                <th>{{i18n
                    "admin.discourse_workflow.workflows.steps.ai_prompt"
                  }}</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {{#each this.processSteps as |step|}}
                <tr
                  data-workflow-step-id={{step.position}}
                  class={{concatClass
                    "process-step-list__row d-admin-row__content"
                  }}
                >
                  <td class="d-admin-row__overview">
                    <div class="process-step-list__position">
                      <strong>
                        {{step.position}}
                      </strong>
                    </div>
                  </td>
                  <td class="d-admin-row__overview">
                    <div class="process-step-list__name">
                      <strong>
                        {{step.name}}
                      </strong>
                    </div>
                  </td>
                  <td class="d-admin-row__overview">
                    <div class="process-step-list__category_name">
                      {{categoryLink step.category}}
                    </div>
                  </td>
                  <td class="d-admin-row__overview">
                    <div class="process-step-list__description">
                      {{step.description}}
                    </div>
                  </td>
                  <td class="d-admin-row__overview">
                    <DToggleSwitch
                      class="process-editor__ai_enabled"
                      @state={{step.ai_enabled}}
                      @label="admin.discourse_workflow.workflows.enabled"
                      {{on "click" (fn this.toggleAiEnabled step)}}
                    />
                  </td>
                  <td class="d-admin-row__overview">
                    <div class="process-step-list__ai_prompt">
                      {{step.ai_prompt}}
                    </div>
                  </td>
                  <td class="d-admin-row__controls">
                    {{#unless (this.isfirstStep step this.processSteps.length)}}
                      <DButton
                        class="process-editor__ai_enabled"
                        @icon="arrow-up"
                        @title="admin.discourse_workflow.workflows.steps.move_up"
                        {{on "click" (fn this.moveUp step)}}
                      />
                    {{/unless}}
                    {{#unless (this.islastStep step this.processSteps.length)}}
                      <DButton
                        class="process-editor__ai_enabled"
                        @icon="arrow-down"
                        @title="admin.discourse_workflow.workflows.steps.move_down"
                        {{on "click" (fn this.moveDown step)}}
                      />
                    {{/unless}}
                    <LinkTo
                      @route="adminPlugins.show.processes.steps.edit"
                      @models={{array @workflow.id step}}
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
          @route="adminPlugins.show.processes.steps.new"
          @label="admin.discourse_workflow.workflows.steps.new"
          @model={{@workflow}}
        />
      {{/if}}
    </section>
  </template>
}
