import ProcessTopicBanner from "../../components/process-topic-banner";

export default <template>
  <ProcessTopicBanner
    @process_step_options={{@outletArgs.model.process_step_options}}
    @process_step_actions={{@outletArgs.model.process_step_actions}}
    @process_step_position={{@outletArgs.model.process_step_position}}
    @process_step_name={{@outletArgs.model.process_step_name}}
    @process_name={{@outletArgs.model.process_name}}
    @process_can_act={{@outletArgs.model.process_can_act}}
    @process_step_entered_at={{@outletArgs.model.process_step_entered_at}}
    @topic_id={{@outletArgs.model.id}}
    @category_id={{@outletArgs.model.category_id}}
  />
</template>
