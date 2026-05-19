# frozen_string_literal: true

module ProcessManager
  module Admin
    class ProcessesController < ::Admin::AdminController
      requires_plugin ::ProcessManager::PLUGIN_NAME

      before_action :find_process, only: %i[edit show update destroy]

      def index
        @processes = Process.order(:enabled).order(:name).order(:id).to_a
        ActiveRecord::Associations::Preloader.new(
          records: @processes,
          associations: {
            workflow_steps: [:category, { workflow_step_options: :workflow_option }],
          },
        ).call
        render_json_dump(
          {
            workflows:
              ActiveModel::ArraySerializer.new(
                @processes,
                each_serializer: ProcessManager::ProcessSerializer,
              ),
          },
        )
      end

      def new
      end

      def edit
        render json: ProcessSerializer.new(@process)
      end

      def show
        render json: ProcessSerializer.new(@process)
      end

      def create
        #byebug
        process = Process.new(process_params)
        process.save!
        render json: ProcessSerializer.new(process)
      end

      def update
        if @process.update(process_params)
          render json: ProcessSerializer.new(@process, root: false)
        else
          render_json_error @process
        end
      end

      def destroy
        if @process.destroy
          head :no_content
        else
          render_json_error @process
        end
      end

      def find_process
        @process = Process.find(params[:id])
      end

      def process_params
        permitted =
          params.require(:workflow).permit(
            :name,
            :description,
            :enabled,
            :overdue_days,
            :show_kanban_tags,
          )

        permitted
      end
    end
  end
end
