import SortableColumn from "discourse/components/topic-list/header/sortable-column";
import { addDiscoveryQueryParam } from "discourse/controllers/discovery/list";
import { withPluginApi } from "discourse/lib/plugin-api";
import { i18n } from "discourse-i18n";
import ProcessNameLink from "./../components/process-name-link";

const WORKFLOW_LIST_ROUTES = ["discovery.processes", "discovery.processCharts"];

const processNameHeader = <template>
  <SortableColumn
    @sortable={{@sortable}}
    @number="false"
    @order="workflow-name"
    @activeOrder={{@activeOrder}}
    @changeSort={{@changeSort}}
    @ascending={{@ascending}}
    @name="workflow-name"
  />
</template>;

const processNameCell = <template>
  <td class="process-name">
    <ProcessNameLink
      @topic_id={{@topic.id}}
      @workflow_name={{@topic.workflow_name}}
      @label={{@topic.workflow_name}}
    />
  </td>
</template>;

const processStepPositionHeader = <template>
  <SortableColumn
    @sortable={{@sortable}}
    @number="true"
    @order="process-step-position"
    @activeOrder={{@activeOrder}}
    @changeSort={{@changeSort}}
    @ascending={{@ascending}}
    @name="process-step-position"
  />
</template>;

const processStepPositionCell = <template>
  <td class="process-step-position">
    <ProcessNameLink
      @topic_id={{@topic.id}}
      @workflow_name={{@topic.workflow_name}}
      @label={{@topic.workflow_step_position}}
    />
  </td>
</template>;

const processStepNameHeader = <template>
  <SortableColumn
    @sortable={{@sortable}}
    @number="false"
    @order="workflow-step-name"
    @activeOrder={{@activeOrder}}
    @changeSort={{@changeSort}}
    @ascending={{@ascending}}
    @name="workflow-step-name"
  />
</template>;

const processStepNameCell = <template>
  <td class="process-step-name">
    <ProcessNameLink
      @topic_id={{@topic.id}}
      @workflow_name={{@topic.workflow_name}}
      @label={{@topic.workflow_step_name}}
    />
  </td>
</template>;

const workflowOverdueHeader = <template>
  <th class="topic-list-data process-overdue-column">
    {{i18n "process-overdue"}}
  </th>
</template>;

const workflowOverdueCell = <template>
  <td class="process-overdue">
    {{#if @topic.workflow_overdue}}
      <span class="process-overdue-indicator">{{i18n
          "discourse_workflow.overdue_indicator"
        }}</span>
    {{/if}}
  </td>
</template>;

export default {
  name: "discourse-workflow-initializer",

  initialize(container) {
    const router = container.lookup("service:router");

    addDiscoveryQueryParam("my_categories", {
      replace: true,
      refreshModel: true,
    });
    addDiscoveryQueryParam("overdue_days", {
      replace: true,
      refreshModel: true,
    });
    addDiscoveryQueryParam("overdue", {
      replace: true,
      refreshModel: true,
    });
    addDiscoveryQueryParam("process_step_position", {
      replace: true,
      refreshModel: true,
    });
    addDiscoveryQueryParam("process_view", {
      replace: true,
      refreshModel: false,
    });
    addDiscoveryQueryParam("chart_weeks", {
      replace: true,
      refreshModel: false,
    });

    withPluginApi((api) => {
      api.addAdminPluginConfigurationNav("discourse-workflow", [
        {
          label: "admin.discourse_workflow.workflows.title",
          route: "adminPlugins.show.processes",
        },
      ]);

      api.addNavigationBarItem({
        name: "processes",
        href: "/processes",
      });

      api.registerValueTransformer("topic-list-item-class", ({ value }) => {
        if (WORKFLOW_LIST_ROUTES.includes(router.currentRouteName)) {
          value.push("process-list");
        }
        return value;
      });

      api.registerValueTransformer(
        "topic-list-columns",
        ({ value: columns }) => {
          if (WORKFLOW_LIST_ROUTES.includes(router.currentRouteName)) {
            columns.add("workflow-name", {
              header: processNameHeader,
              item: processNameCell,
              after: "activity",
            });
          }
          return columns;
        }
      );

      api.registerValueTransformer(
        "topic-list-columns",
        ({ value: columns }) => {
          if (WORKFLOW_LIST_ROUTES.includes(router.currentRouteName)) {
            columns.add("process-step-position", {
              header: processStepPositionHeader,
              item: processStepPositionCell,
              after: "workflow-name",
            });
          }
          return columns;
        }
      );

      api.registerValueTransformer(
        "topic-list-columns",
        ({ value: columns }) => {
          if (WORKFLOW_LIST_ROUTES.includes(router.currentRouteName)) {
            columns.add("workflow-step-name", {
              header: processStepNameHeader,
              item: processStepNameCell,
              after: "process-step-position",
            });
          }
          return columns;
        }
      );

      api.registerValueTransformer(
        "topic-list-columns",
        ({ value: columns }) => {
          if (WORKFLOW_LIST_ROUTES.includes(router.currentRouteName)) {
            columns.add("process-overdue", {
              header: workflowOverdueHeader,
              item: workflowOverdueCell,
              after: "workflow-step-name",
            });
          }
          return columns;
        }
      );

      api.addPostSmallActionIcon("workflow_transition", "right-left");
    });
  },
};
