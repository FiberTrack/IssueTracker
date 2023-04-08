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
  post 'create_multiple_issues', to: 'issues#create_multiple_issues'
  get 'bulk_issues', to: 'issues#bulk_issues'

resources :issues do
  resources :comments
end

end



