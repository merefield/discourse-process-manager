import ProcessStepListEditor from "../../../../../components/process-step-list-editor";

export default <template>
  <ProcessStepListEditor
    @currentProcessStep={{@controller.model}}
    @workflow={{@controller.model.workflow}}
    @processSteps={{@controller.processSteps}}
  />
</template>
