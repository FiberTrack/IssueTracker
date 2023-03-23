Rails.application.routes.draw do
  resources :issues
  resources :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  root 'issues#index'
  get 'show', to: 'issues#show'
end