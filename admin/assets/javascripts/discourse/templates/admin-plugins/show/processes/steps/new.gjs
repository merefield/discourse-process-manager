import ProcessStepListEditor from "../../../../../components/process-step-list-editor";

export default <template>
  <ProcessStepListEditor
    @currentWorkflowStep={{@controller.model}}
    @workflow={{@controller.model.workflow}}
  />
</template>
