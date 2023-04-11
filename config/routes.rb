Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks',
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }

  root 'issues#index'

  resources :issues do
    resources :comments, only: [:create, :destroy]
     member do
      delete :destroy_single_attachment
    end
    resources :attachments
    put :block, on: :member
  end

  get 'update_avatar_view', to: 'users#update_profile_avatar'
  post 'upload_avatar', to: 'users#update_avatar'
  post 'create_multiple_issues', to: 'issues#create_multiple_issues'
  get 'bulk_issues', to: 'issues#bulk_issues'
  post '/issues/:issue_id/attachments', to: 'attachments#create', as: "createatt"
end
