Rails.application.routes.draw do
  root to: "pages#home"

  %w{env help home}.each { |p| get p => "pages##{p}" }
  get "sign_in" => "sessions#new"

  resources :notes
  resources :trips do
    resources :days, except: [:index]
  end
  resources :users

  resource :session, only: [:new, :create, :destroy]
  resource :otp_secret, only: [:new, :create]
end
