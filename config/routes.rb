Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks',
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }


  root 'issues#index'
  put '/issues/:id/add_deadline', to: 'issues#add_deadline', as: 'add_deadline_issue'
  put '/issues/:id/delete_deadline', to: 'issues#delete_deadline', as: 'delete_deadline_issue'

  resources :issues do
    resources :comments, only: [:create, :destroy]
     member do
      delete :destroy_single_attachment
    end
    resources :attachments
  end

  get 'update_avatar_view', to: 'users#update_profile_avatar'
  post 'upload_avatar', to: 'users#update_avatar'
  post 'upload_bio', to: 'users#update_bio'
  post 'update_profile', to: 'users#update_profile'
  get 'bulk_issues', to: 'issues#bulk_issues'





  get 'visualize_account', to: 'users#visualize'


  put '/issues/:id/block', to: 'issues#block', as: 'block_issue'


  ##API

  post '/issues/create_multiple', to: 'issues#create_multiple_issues', as: 'create_multiple_issues'


  delete '/issues/:id', to: 'issues#destroy'
  get '/issues', to: 'issues#index'
  post '/issues', to: 'issues#create'

  get '/issues/:issue_id/attachments', to: 'attachments#get_attachments'
  post '/issues/:issue_id/attachments', to: 'attachments#create', as: "create_at"
  delete '/attachments/:id', to: 'attachments#destroy_attachment', as: 'destroy_attachment'

  post '/issues/:id/comments/new', to: 'issues#create_comment'
  get '/issues/:id/comments', to: 'issues#get_comments'
  post '/issues/:id/block', to: 'issues#block'
  post '/issues/:id/deadline', to: 'issues#add_deadline'
  get '/issues/:id/activities', to: 'issues#get_activities'
  get '/users', to: 'users#all_users_as_json'
  get '/users/:usuari_id', to: 'users#show_user'
  get '/users/:usuari_id/activities', to: 'users#get_activities_user'
  get '/users/:usuari_id/watchers', to: 'users#get_watchers_user'
  post '/user/update', to: 'users#update_profile'
  put '/issues/:id', to: 'issues#update'


end
