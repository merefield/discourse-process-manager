import DPageSubheader from "discourse/components/d-page-subheader";
import { i18n } from "discourse-i18n";
import ProcessListEditor from "../../../../components/process-list-editor";

export default <template>
  <div class="discourse-process-manager admin-detail">
    <DPageSubheader
      @titleLabel={{i18n "admin.process_manager.processes.title"}}
      @descriptionLabel={{i18n "admin.process_manager.processes.instructions"}}
    >
      <:actions as |actions|>
        <actions.Primary
          @label="admin.process_manager.processes.new"
          @title="admin.process_manager.processes.new"
          @route="adminPlugins.show.processes.new"
          @routeModels="discourse-process-manager"
          @icon="plus"
          class="admin-processes-new"
        />
      </:actions>
    </DPageSubheader>

    <div class="processes-list">
      {{#if @controller.model.content.length}}
        <ProcessListEditor @processes={{@controller.model.content}} />
      {{else}}
        {{i18n "admin.process_manager.processes.none"}}
      {{/if}}
    </div>
  </div>
</template>
