Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks',
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }
  resources :issues
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  root 'issues#index'
  get 'show', to: 'issues#show'
end

