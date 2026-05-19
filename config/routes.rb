# frozen_string_literal: true
Discourse::Application.routes.draw do
  mount ::ProcessManager::Engine, at: "discourse-workflow"

  scope "/admin/plugins/discourse-workflow" do
    resources :workflows, controller: "process_manager/admin/workflows" do
      resources :workflow_steps,
                only: %i[index edit show],
                controller: "process_manager/admin/workflow_steps" do
        resources :workflow_step_options,
                  only: %i[index edit show],
                  controller: "process_manager/admin/workflow_step_options"
      end
    end
    resources :workflow_steps,
              only: %i[create update destroy],
              path: "workflow_steps",
              controller: "process_manager/admin/workflow_steps" do
      member { put :reorder }
    end
    resources :workflow_step_options,
              only: %i[create update destroy],
              path: "workflow_step_options",
              controller: "process_manager/admin/workflow_step_options"
    resources :workflow_options,
              only: %i[index],
              path: "workflow_options",
              controller: "process_manager/admin/workflow_options"
  end
end

::ProcessManager::Engine.routes.draw do
  post "/act/:topic_id" => "workflow_action#act"
  get "/visualisation/:topic_id" => "workflow_visualisation#network"
  get "/charts" => "workflow_charts#index"
end
