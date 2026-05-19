import ProcessStepOptionListEditor from "../../../../../../components/process-step-option-list-editor";

export default <template>
  <ProcessStepOptionListEditor
    @currentWorkflowStepOption={{@controller.model}}
    @workflowStep={{@controller.model.workflowStep}}
    @workflowSteps={{@controller.workflowSteps}}
    @workflowOptions={{@controller.workflowOptions}}
  />
</template>
