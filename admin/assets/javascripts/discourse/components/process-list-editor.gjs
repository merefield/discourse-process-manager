import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { LinkTo } from "@ember/routing";
import { service } from "@ember/service";
import DBreadcrumbsItem from "discourse/components/d-breadcrumbs-item";
import DToggleSwitch from "discourse/components/d-toggle-switch";
import concatClass from "discourse/helpers/concat-class";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { i18n } from "discourse-i18n";
import ProcessEditor from "./process-editor";

export default class ProcessListEditor extends Component {
  @service adminPluginNavManager;

  @action
  async toggleEnabled(process) {
    const oldValue = process.enabled;
    const newValue = !oldValue;

    try {
      process.set("enabled", newValue);
      await process.save();
    } catch (err) {
      process.set("enabled", oldValue);
      popupAjaxError(err);
    }
  }

  <template>
    <DBreadcrumbsItem
      @path="/admin/plugins/{{this.adminPluginNavManager.currentPlugin.name}}/processes"
      @label={{i18n "admin.discourse_workflow.workflows.short_title"}}
    />
    <section class="process-list-editor__current admin-detail pull-left">
      {{#if @currentProcess}}
        <ProcessEditor @process={{@currentProcess}} @processes={{@processes}} />
      {{else}}
        {{#if @processes}}
          <table class="content-list process-list-editor d-admin-table">
            <thead>
              <tr>
                <th>{{i18n "admin.discourse_workflow.workflows.enabled"}}</th>
                <th>{{i18n "admin.discourse_workflow.workflows.name"}}</th>
                <th>{{i18n
                    "admin.discourse_workflow.workflows.description"
                  }}</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {{#each @processes as |process|}}
                <tr
                  data-workflow-id={{process.id}}
                  class={{concatClass
                    "process-list__row d-admin-row__content"
                    (if process.priority "priority")
                  }}
                >
                  <td class="d-admin-row__detail">
                    <DToggleSwitch
                      @state={{process.enabled}}
                      {{on "click" (fn this.toggleEnabled process)}}
                    />
                  </td>
                  <td class="d-admin-row__overview">
                    <div class="process-list__name">
                      <strong>
                        {{process.name}}
                      </strong>
                    </div>
                  </td>
                  <td class="d-admin-row__overview">
                    <div class="process-list__description">
                      {{process.description}}
                    </div>
                  </td>
                  <td class="d-admin-row__controls">
                    <LinkTo
                      @route="adminPlugins.show.processes.edit"
                      @model={{process}}
                      class="btn btn-text btn-small"
                    >{{i18n "admin.discourse_workflow.workflows.edit"}}
                    </LinkTo>
                  </td>
                </tr>
              {{/each}}
            </tbody>
          </table>
        {{else}}
          <div class="process-list-editor__empty empty-state">
            <p>{{i18n "admin.discourse_workflow.workflows.none"}}</p>
            <LinkTo
              @route="adminPlugins.show.processes.new"
              class="btn btn-primary process-list-editor__empty-new-button"
            >
              {{i18n "admin.discourse_workflow.workflows.new"}}
            </LinkTo>
          </div>
        {{/if}}
      {{/if}}
    </section>
  </template>
}
