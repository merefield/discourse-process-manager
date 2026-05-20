# frozen_string_literal: true

module ProcessManager
  module Admin
    class ProcessOptionsController < ::Admin::AdminController
      requires_plugin ::ProcessManager::PLUGIN_NAME

      def index
        process_options = ProcessOption.all.order(:id)
        render_json_dump(
          {
            process_options:
              ActiveModel::ArraySerializer.new(
                process_options,
                each_serializer: ProcessManager::ProcessOptionSerializer,
              ),
          },
        )
      end
    end
  end
end
