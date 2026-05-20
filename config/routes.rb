# frozen_string_literal: true
Discourse::Application.routes.draw do
  mount ::ProcessManager::Engine, at: "discourse-process-manager"

  scope "/admin/plugins/discourse-process-manager" do
    resources :processes, controller: "process_manager/admin/processes" do
      resources :process_steps,
                only: %i[index edit show],
                controller: "process_manager/admin/process_steps" do
        resources :process_step_options,
                  only: %i[index edit show],
                  controller: "process_manager/admin/process_step_options"
      end
    end
    resources :process_steps,
              only: %i[create update destroy],
              path: "process_steps",
              controller: "process_manager/admin/process_steps" do
      member { put :reorder }
    end
    resources :process_step_options,
              only: %i[create update destroy],
              path: "process_step_options",
              controller: "process_manager/admin/process_step_options"
    resources :process_options,
              only: %i[index],
              path: "process_options",
              controller: "process_manager/admin/process_options"
  end
end

::ProcessManager::Engine.routes.draw do
  post "/act/:topic_id" => "process_action#act"
  get "/visualisation/:topic_id" => "process_visualisation#network"
  get "/charts" => "process_charts#index"
end
