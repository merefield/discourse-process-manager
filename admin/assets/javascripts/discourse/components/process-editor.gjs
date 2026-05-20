import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { Input } from "@ember/component";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { later } from "@ember/runloop";
import { service } from "@ember/service";
import BackButton from "discourse/components/back-button";
import DBreadcrumbsItem from "discourse/components/d-breadcrumbs-item";
import DButton from "discourse/components/d-button";
import Textarea from "discourse/components/d-textarea";
import DToggleSwitch from "discourse/components/d-toggle-switch";
import { popupAjaxError } from "discourse/lib/ajax-error";
import I18n, { i18n } from "discourse-i18n";
import ProcessStepListEditor from "./process-step-list-editor";
import ProcessVisualEditor from "./process-visual-editor";

export default class ProcessEditor extends Component {
  @service adminPluginNavManager;
  @service router;
  @service store;
  @service dialog;
  @service toasts;

  @tracked isSaving = false;
  @tracked editingModel = null;
  @tracked showDelete = false;
  @tracked stepsView = "list";

  get showingStepsList() {
    return this.stepsView === "list";
  }

  get showingStepsVisual() {
    return this.stepsView === "visual";
  }

  @action
  showStepsList() {
    this.stepsView = "list";
  }

  @action
  showStepsVisual() {
    this.stepsView = "visual";
  }

  @action
  updateModel() {
    this.editingModel = this.args.process.workingCopy();
    this.showDelete = !this.args.process.isNew && !this.args.process.system;
  }

  @action
  async save() {
    this.isSaving = true;

    const backupModel = this.args.process.workingCopy();

    this.args.process.setProperties(this.editingModel);
    try {
      await this.args.process.save();
      this.#sortProcesses();
      this.toasts.success({
        data: { message: i18n("admin.process_manager.processes.saved") },
        duration: 2000,
      });
      this.router.transitionTo(
        "adminPlugins.show.processes",
        this.store.findAll("process")
      );
    } catch (e) {
      this.args.process.setProperties(backupModel);
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
      message: i18n("admin.process_manager.processes.confirm_delete"),
      didConfirm: () => {
        return this.args.process.destroyRecord().then(() => {
          this.router.transitionTo(
            "adminPlugins.show.processes",
            this.store.findAll("process")
          );
        });
      },
    });
  }

  @action
  async toggleEnabled() {
    await this.toggleField("enabled");
  }

  @action
  toggleShowKanbanTags() {
    this.editingModel.set(
      "show_kanban_tags",
      !this.editingModel.show_kanban_tags
    );
  }

  async toggleField(field, sortProcesses) {
    this.args.process.set(field, !this.args.process[field]);
    this.editingModel.set(field, this.args.process[field]);
    if (!this.args.process.isNew) {
      try {
        const args = {};
        args[field] = this.args.process[field];

        await this.args.process.update(args);
        if (sortProcesses) {
          this.#sortProcesses();
        }
      } catch (e) {
        popupAjaxError(e);
      }
    }
  }

  get showSteps() {
    return this.args.process.id > 0;
  }

  validationWarningMessage(warning) {
    const code = warning.code;

    if (code === "duplicate_step_positions") {
      return i18n(
        "admin.process_manager.processes.validation.duplicate_step_positions",
        {
          positions: (warning.positions || []).join(", "),
        }
      );
    }

    if (code === "orphan_target_steps") {
      return i18n(
        "admin.process_manager.processes.validation.orphan_target_steps",
        {
          count: (warning.option_ids || []).length,
        }
      );
    }

    if (code === "missing_option_labels") {
      return i18n(
        "admin.process_manager.processes.validation.missing_option_labels",
        {
          slugs: (warning.slugs || []).join(", "),
        }
      );
    }

    return code;
  }

  #sortProcesses() {
    const sorted = this.args.processes.toArray().sort((a, b) => {
      return a.name.localeCompare(b.name);
    });
    this.args.processes.clear();
    this.args.processes.setObjects(sorted);
  }

  <template>
    <DBreadcrumbsItem
      @path="/admin/plugins/{{this.adminPluginNavManager.currentPlugin.name}}/processes/{{@model.id}}"
      @label={{i18n "admin.process_manager.processes.process.short_title"}}
    />
    <BackButton
      @route="adminPlugins.show.processes"
      @label="admin.process_manager.processes.back"
    />
    {{#if @process.name}}
      <h2>{{I18n.t
          "admin.process_manager.processes.process.editing.title"
          process_name=@process.name
        }}</h2>
    {{else}}
      <h2>{{I18n.t "admin.process_manager.processes.process.new.title"}}</h2>
    {{/if}}
    <form
      class="form-horizontal process-editor"
      {{didUpdate this.updateModel @model.id}}
      {{didInsert this.updateModel @model.id}}
    >
      {{#if @process.validation_warnings.length}}
        <div class="control-group process-editor__validation-warnings">
          <label>{{i18n
              "admin.process_manager.processes.validation.title"
            }}</label>
          <ul>
            {{#each @process.validation_warnings as |warning|}}
              <li>{{this.validationWarningMessage warning}}</li>
            {{/each}}
          </ul>
        </div>
      {{/if}}
      <div class="control-group">
        <DToggleSwitch
          class="process-editor__enabled"
          @state={{@process.enabled}}
          @label="admin.process_manager.processes.enabled"
          {{on "click" this.toggleEnabled}}
        />
      </div>
      <div class="control-group">
        <label>{{I18n.t "admin.process_manager.processes.name"}}</label>
        <Input
          class="process-editor__name"
          @type="text"
          @value={{this.editingModel.name}}
          disabled={{this.editingModel.system}}
        />
      </div>
      <div class="control-group">
        <label>{{I18n.t "admin.process_manager.processes.description"}}</label>
        <Textarea
          class="process-editor__description"
          @value={{this.editingModel.description}}
          disabled={{this.editingModel.system}}
        />
      </div>
      <div class="control-group">
        <label>{{I18n.t "admin.process_manager.processes.overdue_days"}}</label>
        <Input
          class="process-editor__overdue-days"
          @type="number"
          min="0"
          @value={{this.editingModel.overdue_days}}
          disabled={{this.editingModel.system}}
        />
        <p>{{i18n "admin.process_manager.processes.overdue_days_help"}}</p>
      </div>
      <div class="control-group">
        <DToggleSwitch
          class="process-editor__show-kanban-tags"
          @state={{this.editingModel.show_kanban_tags}}
          @label="admin.process_manager.processes.show_kanban_tags"
          @disabled={{this.editingModel.system}}
          {{on "click" this.toggleShowKanbanTags}}
        />
        <p>{{i18n "admin.process_manager.processes.show_kanban_tags_help"}}</p>
      </div>
      {{#if @process.id}}
        <div class="control-group">
          <label>{{i18n
              "admin.process_manager.processes.kanban_compatibility.label"
            }}</label>
          <p>
            {{#if @process.kanban_compatible}}
              <span class="process-editor__kanban-compatible">
                {{i18n
                  "admin.process_manager.processes.kanban_compatibility.compatible"
                }}
              </span>
            {{else}}
              <span class="process-editor__kanban-incompatible">
                {{i18n
                  "admin.process_manager.processes.kanban_compatibility.incompatible"
                }}
              </span>
            {{/if}}
          </p>
          <p>{{i18n
              "admin.process_manager.processes.kanban_compatibility.help"
            }}</p>
        </div>
      {{/if}}
      {{#if this.showSteps}}
        <div class="control-group process-editor__steps-panel">
          <div class="process-editor__steps-tabs">
            <button
              type="button"
              class={{if
                this.showingStepsList
                "btn btn-primary process-editor__steps-tab"
                "btn btn-default process-editor__steps-tab"
              }}
              {{on "click" this.showStepsList}}
            >
              {{i18n "admin.process_manager.processes.steps.tabs.list"}}
            </button>
            <button
              type="button"
              class={{if
                this.showingStepsVisual
                "btn btn-primary process-editor__steps-tab"
                "btn btn-default process-editor__steps-tab"
              }}
              {{on "click" this.showStepsVisual}}
            >
              {{i18n "admin.process_manager.processes.steps.tabs.visual"}}
            </button>
          </div>

          {{#if this.showingStepsList}}
            <ProcessStepListEditor
              class="process-editor__steps"
              @process={{@process}}
              @disabled={{this.editingModel.system}}
              @onChange={{this.stepsChanged}}
            />
          {{else}}
            <ProcessVisualEditor
              @process={{@process}}
              @disabled={{this.editingModel.system}}
            />
          {{/if}}
        </div>
      {{/if}}
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
