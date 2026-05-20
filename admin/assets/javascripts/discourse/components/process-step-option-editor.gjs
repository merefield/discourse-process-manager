import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn, hash } from "@ember/helper";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { later } from "@ember/runloop";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import { popupAjaxError } from "discourse/lib/ajax-error";
import DropdownSelectBox from "discourse/select-kit/components/dropdown-select-box";
import I18n, { i18n } from "discourse-i18n";
import ProcessBackButton from "./process-back-button";

export default class ProcessStepOptionEditor extends Component {
  @service router;
  @service dialog;
  @service toasts;

  @tracked isSaving = false;
  @tracked editingModel = null;
  @tracked showDelete = false;

  @action
  updateModel() {
    this.editingModel = this.args.currentProcessStepOption.workingCopy();
    this.showDelete =
      !this.args.currentProcessStepOption.isNew &&
      !this.args.currentProcessStepOption.system;
  }

  @action
  updateCategory(categoryId) {
    this.editingModel.category_id = categoryId;
  }

  @action
  async save() {
    this.isSaving = true;

    const backupModel = this.args.currentProcessStepOption.workingCopy();

    this.args.currentProcessStepOption.setProperties(this.editingModel);
    try {
      await this.args.currentProcessStepOption.save();
      this.isSaving = false;
      this.toasts.success({
        data: {
          message: i18n("admin.process_manager.processes.steps.saved"),
        },
        duration: 2000,
      });
      this.router.transitionTo(
        "adminPlugins.show.processes.steps.edit",
        this.args.currentProcessStepOption.process_step_id
      );
    } catch (e) {
      this.args.currentProcessStepOption.setProperties(backupModel);
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
      message: i18n("admin.process_manager.processes.steps.confirm_delete"),
      didConfirm: () => {
        return this.args.currentProcessStepOption.destroyRecord().then(() => {
          this.toasts.success({
            data: {
              message: i18n("admin.process_manager.processes.steps.deleted"),
            },
            duration: 2000,
          });
          this.router.transitionTo(
            "adminPlugins.show.processes.edit",
            this.args.currentProcessStepOption.process_id
          );
        });
      },
    });
  }

  get availableSteps() {
    const steps = this.args.processSteps || [];
    const filteredSteps = steps
      .map(({ id, name, description }) => ({ id, name, description }))
      .filter((step) => step.id !== this.args.processStep.id);
    return filteredSteps;
  }

  <template>
    <ProcessBackButton
      @route="adminPlugins.show.processes.steps.edit"
      @model={{@currentProcessStepOption.process_step_id}}
    />
    {{#if @currentProcessStepOption.id}}
      <h2>{{I18n.t
          "admin.process_manager.processes.process.step.option.editing.title"
          position=@currentProcessStepOption.position
        }}</h2>
    {{else}}
      <h2>{{I18n.t
          "admin.process_manager.processes.process.step.option.new.title"
        }}</h2>
    {{/if}}
    <form
      class="form-horizontal process-step-editor"
      {{didUpdate this.updateModel @currentProcessStepOption.id}}
      {{didInsert this.updateModel @currentProcessStepOption.id}}
    >
      <div class="control-group">
        <label>{{I18n.t "admin.process_manager.processes.name"}}</label>
        <DropdownSelectBox
          @value={{this.editingModel.process_option_id}}
          @content={{@processOptions}}
          @onChange={{fn (mut this.editingModel.process_option_id)}}
          @options={{hash
            disabled=this.editingModel.system
            none="admin.process_manager.processes.steps.options.select_an_option"
          }}
        />
      </div>
      <div class="control-group">
        <label>{{I18n.t
            "admin.process_manager.processes.steps.options.target_step"
          }}</label>
        <DropdownSelectBox
          @value={{this.editingModel.target_step_id}}
          @content={{this.availableSteps}}
          @onChange={{fn (mut this.editingModel.target_step_id)}}
          @options={{hash
            disabled=this.editingModel.system
            none="admin.process_manager.processes.steps.options.no_target_step"
          }}
        />
      </div>
      <div class="control-group process-editor__action_panel">
        <DButton
          class="btn-primary process-editor__save"
          @action={{this.save}}
          @disabled={{this.isSaving}}
        >{{I18n.t "admin.process_manager.processes.save"}}</DButton>
        {{#if this.showDelete}}
          <DButton
            @action={{this.delete}}
            class="btn-danger process-editor__delete"
          >
            {{I18n.t "admin.process_manager.processes.delete"}}
          </DButton>
        {{/if}}
      </div>
    </form>
  </template>
}
