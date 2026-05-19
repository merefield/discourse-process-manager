# frozen_string_literal: true

module ProcessManager
  class ProcessStepSerializer < ApplicationSerializer
    attributes :id,
               :workflow_id,
               :category_id,
               :position,
               :slug,
               :name,
               :description,
               :overdue_days,
               :ai_enabled,
               :ai_prompt

    has_many :workflow_step_options,
             serializer: ProcessStepOptionSerializer,
             embed: :object,
             key: :workflow_step_options
    has_one :category, serializer: ProcessCategorySerializer, embed: :object

    def category
      object.category
    end
  end
end
