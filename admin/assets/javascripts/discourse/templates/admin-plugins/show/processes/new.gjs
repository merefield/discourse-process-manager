import ProcessListEditor from "../../../../components/process-list-editor";

export default <template>
  <ProcessListEditor
    @processes={{@controller.allProcesses}}
    @currentProcess={{@controller.model}}
  />
</template>
