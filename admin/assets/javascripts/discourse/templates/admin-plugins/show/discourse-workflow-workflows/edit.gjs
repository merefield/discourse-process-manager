import ProcessListEditor from "../../../../components/process-list-editor";

export default <template>
  <ProcessListEditor
    @workflows={{@controller.allWorkflows}}
    @currentWorkflow={{@controller.model}}
  />
</template>
