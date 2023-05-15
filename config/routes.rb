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
  post 'create_multiple_issues', to: 'issues#create_multiple_issues'
  get 'bulk_issues', to: 'issues#bulk_issues'

  post '/issues/:issue_id/attachments', to: 'attachments#create', as: "create_at"


  get 'visualize_account', to: 'users#visualize'

  put '/issues/:id/block', to: 'issues#block', as: 'block_issue'


  ##API
  delete '/issues/:id', to: 'issues#destroy'
  get '/issues', to: 'issues#index'
  post '/issues/new', to: 'issues#create'
  post '/issues/:id/comments/new', to: 'issues#create_comment'
  get '/issues/:id/comments', to: 'issues#get_comments'
  post '/issues/:id/block', to: 'issues#block'
  post '/issues/:id/deadline', to: 'issues#add_deadline'

end
