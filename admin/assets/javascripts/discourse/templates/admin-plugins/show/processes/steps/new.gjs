import ProcessStepListEditor from "../../../../../components/process-step-list-editor";

export default <template>
  <ProcessStepListEditor
    @currentProcessStep={{@controller.model}}
    @process={{@controller.model.process}}
  />
</template>
