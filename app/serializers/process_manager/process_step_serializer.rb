# frozen_string_literal: true

module ProcessManager
  class ProcessStepSerializer < ApplicationSerializer
    attributes :id,
               :process_id,
               :category_id,
               :position,
               :slug,
               :name,
               :description,
               :overdue_days,
               :ai_enabled,
               :ai_prompt

    has_many :process_step_options,
             serializer: ProcessStepOptionSerializer,
             embed: :object,
             key: :process_step_options
    has_one :category, serializer: ProcessCategorySerializer, embed: :object

    def process_id
      object.process_id
    end

    def category
      object.category
    end
  end
end
