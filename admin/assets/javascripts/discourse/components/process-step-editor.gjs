import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { Input } from "@ember/component";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { later } from "@ember/runloop";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import Textarea from "discourse/components/d-textarea";
import DToggleSwitch from "discourse/components/d-toggle-switch";
import { popupAjaxError } from "discourse/lib/ajax-error";
import CategoryChooser from "discourse/select-kit/components/category-chooser";
import not from "discourse/truth-helpers/helpers/not";
import I18n, { i18n } from "discourse-i18n";
import ProcessBackButton from "./process-back-button";
import ProcessStepOptionListEditor from "./process-step-option-list-editor";

export default class ProcessStepEditor extends Component {
  @service router;
  @service dialog;
  @service toasts;

  @tracked isSaving = false;
  @tracked editingModel = null;
  @tracked showDelete = false;

  @action
  updateModel() {
    this.editingModel = this.args.currentProcessStep.workingCopy();
    this.showDelete =
      !this.args.currentProcessStep.isNew &&
      !this.args.currentProcessStep.system;
  }

  @action
  updateCategory(categoryId) {
    this.editingModel.category_id = categoryId;
  }

  @action
  async save() {
    this.isSaving = true;

    const backupModel = this.args.currentProcessStep.workingCopy();
    this.args.currentProcessStep.setProperties(this.editingModel);
    try {
      await this.args.currentProcessStep.save();
      this.isSaving = false;
      this.toasts.success({
        data: {
          message: i18n("admin.discourse_workflow.workflows.steps.saved"),
        },
        duration: 2000,
      });
      this.router.transitionTo(
        "adminPlugins.show.processes.edit",
        this.args.currentProcessStep.workflow_id,
        { queryParams: { refresh: true } }
      );
    } catch (e) {
      this.args.currentProcessStep.setProperties(backupModel);
      popupAjaxError(e);
    } finally {
      later(() => {
        this.isSaving = false;
      }, 1000);
    }
  }

  @action
  delete() {
    return this.dialog.confirm({
      message: i18n("admin.discourse_workflow.workflows.steps.confirm_delete"),
      didConfirm: () => {
        return this.args.currentProcessStep.destroyRecord().then(() => {
          this.toasts.success({
            data: {
              message: i18n("admin.discourse_workflow.workflows.steps.deleted"),
            },
            duration: 2000,
          });

          // this.args.currentProcessSteps.removeObject(this.args.currentProcessStep);
          this.router.transitionTo(
            "adminPlugins.show.processes.edit",
            this.args.currentProcessStep.workflow_id,
            { queryParams: { refresh: true } }
          );
        });
      },
    });
  }

  @action
  async toggleAiEnabled() {
    await this.toggleField("ai_enabled");
  }

  async toggleField(field, sortProcessSteps) {
    this.args.currentProcessStep.set(
      field,
      !this.args.currentProcessStep[field]
    );
    this.editingModel.set(field, this.args.currentProcessStep[field]);
    if (!this.args.currentProcessStep.isNew) {
      try {
        const args = {};
        args[field] = this.args.currentProcessStep[field];

        await this.args.currentProcessStep.update(args);
        if (sortProcessSteps) {
          this.sortProcessSteps();
        }
      } catch (e) {
        popupAjaxError(e);
      }
    }
  }

  get showStepOptions() {
    return this.args.currentProcessStep.id > 0;
  }

  <template>
    <ProcessBackButton
      @route="adminPlugins.show.processes.edit"
      @model={{@currentProcessStep.workflow_id}}
    />
    {{#if @currentProcessStep.id}}
      <h2>{{I18n.t
          "admin.discourse_workflow.workflows.workflow.step.editing.title"
          workflow_step_name=this.editingModel.name
        }}</h2>
    {{else}}
      <h2>{{I18n.t
          "admin.discourse_workflow.workflows.workflow.step.new.title"
        }}</h2>
    {{/if}}
    <form
      class="form-horizontal process-step-editor"
      {{didUpdate this.updateModel @currentProcessStep.id}}
      {{didInsert this.updateModel @currentProcessStep.id}}
    >
      <div class="control-group">
        <label>{{I18n.t "admin.discourse_workflow.workflows.name"}}</label>
        <Input
          class="process-editor__name"
          @type="text"
          @value={{this.editingModel.name}}
          disabled={{this.editingModel.system}}
        />
      </div>
      <div class="control-group">
        <label>{{I18n.t
            "admin.discourse_workflow.workflows.steps.category"
          }}</label>
        <CategoryChooser
          @value={{this.editingModel.category_id}}
          @onChangeCategory={{fn (mut this.editingModel.category_id)}}
          disabled={{this.editingModel.system}}
        />
      </div>
      <div class="control-group">
        <label>{{I18n.t
            "admin.discourse_workflow.workflows.description"
          }}</label>
        <Textarea
          class="process-editor__description"
          @value={{this.editingModel.description}}
          disabled={{this.editingModel.system}}
        />
      </div>
      <div class="control-group">
        <label>{{I18n.t
            "admin.discourse_workflow.workflows.steps.overdue_days"
          }}</label>
        <Input
          class="process-step-editor__overdue-days"
          @type="number"
          min="0"
          @value={{this.editingModel.overdue_days}}
          disabled={{this.editingModel.system}}
        />
        <p>{{i18n
            "admin.discourse_workflow.workflows.steps.overdue_days_help"
          }}</p>
      </div>
      <div class="control-group">
        <DToggleSwitch
          class="process-editor__enabled"
          @state={{this.editingModel.ai_enabled}}
          @label="admin.discourse_workflow.workflows.steps.ai_enabled"
          {{on "click" this.toggleAiEnabled}}
        />
      </div>
      <div class="control-group">
        <label>{{I18n.t
            "admin.discourse_workflow.workflows.steps.ai_prompt"
          }}</label>
        <Textarea
          class="process-editor__ai_prompt"
          @value={{this.editingModel.ai_prompt}}
          disabled={{not this.editingModel.ai_enabled}}
        />
      </div>
      {{#if this.showStepOptions}}
        <div class="control-group">
          <ProcessStepOptionListEditor
            class="process-editor__steps_options"
            @processStep={{@currentProcessStep}}
            @processSteps={{@processSteps}}
            @disabled={{this.editingModel.system}}
            @onChange={{this.stepOptionsChanged}}
          />
        </div>
      {{/if}}
      <div class="control-group process-editor__action_panel">
        <DButton
          class="btn-primary process-editor__save"
          @action={{this.save}}
          @disabled={{this.isSaving}}
        >{{I18n.t "admin.discourse_workflow.workflows.save"}}</DButton>
        {{#if this.showDelete}}
          <DButton
            @action={{this.delete}}
            class="btn-danger process-editor__delete"
          >
            {{I18n.t "admin.discourse_workflow.workflows.delete"}}
          </DButton>
        {{/if}}
      </div>
    </form>
  </template>
}
