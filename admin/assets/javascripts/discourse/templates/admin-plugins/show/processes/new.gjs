import ProcessListEditor from "../../../../components/process-list-editor";

export default <template>
  <ProcessListEditor
    @workflows={{@controller.allProcesses}}
    @currentWorkflow={{@controller.model}}
  />
</template>
