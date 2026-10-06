Rails.application.routes.draw do
  devise_for :users, skip: :registrations

  root "dashboard#show"

  resources :conversations, only: %i[ index show new create ] do
    member do
      patch :take_over
      patch :hand_back
      patch :close
      patch :reopen
    end
    resources :messages, only: :create
  end

  resources :tickets
  resources :message_templates, path: "templates", only: %i[ index show new create destroy ] do
    post :sync, on: :collection
  end
  resources :contacts, only: %i[ index show edit update ]

  namespace :admin do
    resources :users, except: :show
  end

  namespace :webhooks do
    get "whatsapp", to: "whatsapp#verify"
    post "whatsapp", to: "whatsapp#receive"
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
