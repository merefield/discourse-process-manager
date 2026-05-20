# frozen_string_literal: true

module ProcessManager
  module Admin
    class ProcessStepsController < ::Admin::AdminController
      requires_plugin ::ProcessManager::PLUGIN_NAME

      before_action :set_process, only: %i[index new create]
      before_action :set_process_step, only: %i[show edit update destroy reorder]

      def index
        @process_steps =
          if @process.present?
            ProcessStep.where(process_id: @process.id).order(:position).to_a
          else
            ProcessStep.all.order(:position).to_a
          end
        ActiveRecord::Associations::Preloader.new(
          records: @process_steps,
          associations: [:category, { process_step_options: :process_option }],
        ).call
        process_categories = visual_categories_for(@process_steps)
        render_json_dump(
          {
            process_steps:
              ActiveModel::ArraySerializer.new(
                @process_steps,
                each_serializer: ProcessManager::ProcessStepSerializer,
              ),
            process_categories:
              ActiveModel::ArraySerializer.new(
                process_categories,
                each_serializer: ProcessManager::ProcessCategorySerializer,
              ),
          },
        )
      end

      def show
      end

      def new
        process_step = ProcessStep.new(process_step_params)
        if process_step.save
          render json: {
                   process_step: ProcessStepSerializer.new(process_step, root: false),
                 },
                 status: :created
        else
          render_json_error process_step
        end
      end

      def create
        process_step = ProcessStep.new(process_step_params)
        if !process_step.position.present?
          if ProcessStep.count == 0 ||
               ProcessStep.where(process_id: process_step.process_id).count == 0
            process_step.position = 1
          else
            process_step.position =
              ProcessStep.where(process_id: process_step.process_id).maximum(:position).to_i + 1
          end
        end
        if process_step.save
          render json: {
                   process_step: ProcessStepSerializer.new(process_step, root: false),
                 },
                 status: :created
        else
          render_json_error process_step
        end
      end

      def edit
      end

      def update
        if @process_step.update(process_step_params)
          render json: {
                   process_step: ProcessStepSerializer.new(@process_step, root: false),
                 },
                 status: :ok
        else
          render_json_error @process_step
        end
      end

      def reorder
        ProcessStep.transaction do
          reorder_params = process_step_reorder_params
          target_position = reorder_params[:position].to_i
          target_steps =
            ProcessStep
              .where(process_id: @process_step.process_id, position: target_position)
              .where.not(id: @process_step.id)

          target_steps.update_all(position: @process_step.position, updated_at: Time.zone.now)
          @process_step.update!(reorder_params)
        end

        render json: {
                 process_step: ProcessStepSerializer.new(@process_step, root: false),
               },
               status: :ok
      rescue ActiveRecord::RecordInvalid => err
        render_json_error err.record
      end

      def destroy
        ProcessStep.transaction do
          ProcessStepOption
            .where(process_step_id: @process_step.id)
            .or(ProcessStepOption.where(target_process_step_id: @process_step.id))
            .destroy_all

          @process_step.destroy!
        end

        head :no_content
      rescue ActiveRecord::RecordNotDestroyed => err
        render_json_error err.record || @process_step
      end

      private

      def set_process
        process_id = params.dig(:process_id)
        if process_id.present?
          @process = Process.find(process_id)
        else
          @process = nil
        end
      end

      def set_process_step
        @process_step = ProcessStep.find(params[:id])
      end

      def process_step_params
        permitted =
          params.require(:process_step).permit(
            :process_id,
            :position,
            :name,
            :description,
            :category_id,
            :ai_enabled,
            :ai_prompt,
            :overdue_days,
          )

        permitted
      end

      def process_step_reorder_params
        params.require(:process_step).permit(:position, :category_id)
      end

      def visual_categories_for(process_steps)
        categories = process_steps.filter_map(&:category)
        category_ids = categories.map(&:id)
        parent_category_ids = categories.filter_map(&:parent_category_id).uniq

        if parent_category_ids.present?
          category_ids.concat(Category.where(parent_category_id: parent_category_ids).pluck(:id))
        end

        Category.where(id: category_ids.uniq).order(:position)
      end

      def ensure_admin
        # Your admin constraint logic here
      end
    end
  end
end
