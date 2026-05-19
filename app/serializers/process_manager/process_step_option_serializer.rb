# frozen_string_literal: true

module ProcessManager
  class ProcessStepOptionSerializer < ApplicationSerializer
    attributes :id, :process_option_id, :process_step_id, :process_id, :position, :target_step_id

    has_one :workflow_option,
            serializer: ProcessOptionSerializer,
            embed: :object,
            key: :process_option

    def process_option_id
      object.workflow_option_id
    end

    def process_step_id
      object.workflow_step_id
    end

    def process_id
      object.workflow_step.workflow_id
    end
  end
end
