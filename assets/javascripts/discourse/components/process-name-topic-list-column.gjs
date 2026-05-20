import ProcessNameLink from "./process-name-link";

const ProcessNameTopicListColumn = <template>
  <td class="process-name">
    <ProcessNameLink
      @topic_id={{@topic.id}}
      @process_name={{@topic.process_name}}
      @label={{@topic.process_name}}
    />
  </td>
</template>;

export default ProcessNameTopicListColumn;
