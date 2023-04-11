Rails.application.routes.draw do


  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks',
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }
  resources :issues
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  get 'update_avatar_view', to: 'users#update_profile_avatar'
  post 'upload_avatar', to: 'users#update_avatar'

  put '/issues/:id/add_deadline', to: 'issues#add_deadline', as: 'add_deadline_issue'
  put '/issues/:id/delete_deadline', to: 'issues#delete_deadline', as: 'delete_deadline_issue'


  root 'issues#index'
  get 'show', to: 'issues#show'
  post 'create_multiple_issues', to: 'issues#create_multiple_issues'
  get 'bulk_issues', to: 'issues#bulk_issues'

  put '/issues/:id/block', to: 'issues#block', as: 'block_issue'


resources :issues do
  resources :comments
end

end



