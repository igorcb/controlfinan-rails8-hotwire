Rails.application.routes.draw do
  resource :session
  resource :registration, only: %i[ new create ]
  resources :passwords, param: :token
  resources :current_accounts
  resource :dashboard, only: :show

  # Legacy daily balance search, now a filter on the listing
  get "search_account", to: redirect { |_, req| "/current_accounts?date=#{req.params[:date_calendar_now]}" }

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  root "current_accounts#index"
end
