# frozen_string_literal: true

module ProcessManager
  class ProcessStepOptionSerializer < ApplicationSerializer
    attributes :id,
               :process_option_id,
               :process_step_id,
               :process_id,
               :position,
               :target_process_step_id

    has_one :process_option,
            serializer: ProcessOptionSerializer,
            embed: :object,
            key: :process_option

    def process_option_id
      object.process_option_id
    end

    def process_step_id
      object.process_step_id
    end

    def process_id
      object.process_step.process_id
    end
  end
end
