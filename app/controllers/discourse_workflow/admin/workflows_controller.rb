# frozen_string_literal: true

module DiscourseWorkflow
  module Admin
    class WorkflowsController < ::Admin::AdminController
      requires_plugin ::DiscourseWorkflow::PLUGIN_NAME

      before_action :find_process, only: %i[edit show update destroy]

      def index
        @processes = Workflow.order(:enabled).order(:name).order(:id).to_a
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
                each_serializer: DiscourseWorkflow::WorkflowSerializer,
              ),
          },
        )
      end

      def new
      end

      def edit
        render json: WorkflowSerializer.new(@process)
      end

      def show
        render json: WorkflowSerializer.new(@process)
      end

      def create
        #byebug
        process = Workflow.new(process_params)
        process.save!
        render json: WorkflowSerializer.new(process)
      end

      def update
        if @process.update(process_params)
          render json: WorkflowSerializer.new(@process, root: false)
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
        @process = Workflow.find(params[:id])
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
