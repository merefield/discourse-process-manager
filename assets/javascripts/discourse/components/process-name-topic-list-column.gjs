import ProcessNameLink from "./process-name-link";

const ProcessNameTopicListColumn = <template>
  <td class="process-name">
    <ProcessNameLink
      @topic_id={{@topic.id}}
      @workflow_name={{@topic.workflow_name}}
      @label={{@topic.workflow_name}}
    />
  </td>
</template>;

export default ProcessNameTopicListColumn;
