Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  get "manifest.webmanifest" => "rails/pwa#manifest", defaults: { format: :json }, as: :pwa_manifest
  root "today#show"
  resource :session, only: %i[new create destroy]
  resources :water_entries, only: :create
  resource :sleep_entry, only: :create
  resources :workouts, only: %i[index show create] do
    patch :finish, on: :member
    resources :lifting_sets, only: :create
  end
  get "evolucao", to: "dashboard#show", as: :dashboard
  resources :lab_results, only: %i[index create], path: "exames"
end
