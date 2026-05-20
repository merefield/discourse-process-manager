import ProcessStepOptionListEditor from "../../../../../../components/process-step-option-list-editor";

export default <template>
  <ProcessStepOptionListEditor
    @currentProcessStepOption={{@controller.model}}
    @processStep={{@controller.processStep}}
    @processSteps={{@controller.processSteps}}
    @processOptions={{@controller.processOptions}}
  />
</template>
