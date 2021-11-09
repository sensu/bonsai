require "sidekiq/web"
require "sidekiq-status/web"

Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  VERSION_PATTERN = /[^\/]+/  unless defined?(VERSION_PATTERN) # Allow any value, including "."
  PLATFORM_PATTERN = /[^\/]+/  unless defined?(PLATFORM_PATTERN) # Allow any value, including "."

  apipie

  namespace :api, defaults: { format: :json }  do
    namespace :v1 do
      get 'metrics' => 'metrics#show'
      get 'health' => 'health#show'
      get 'assets' => 'extensions#index', as: :extensions
      get 'assets/:username/:id' => 'extensions#show', as: :extension
      put 'assets/:username/:id' => 'extensions#update', as: :update_extension
      put 'assets/recompile/:username/:id' => 'extensions#sync_repo', as: :extension_recompile
      get 'assets/:username/:extension/versions/:version' => 'extension_versions#show', as: :extension_version, constraints: { version: VERSION_PATTERN }
      get 'assets/:username/:extension/versions/:version/download' => 'extension_versions#download', as: :extension_version_download, constraints: { version: VERSION_PATTERN }
      delete 'assets/:username/:extension/versions/:version' => 'extension_uploads#destroy_version', constraints: { version: VERSION_PATTERN }
      get 'users/:user' => 'users#show', as: :user
      get 'assets/:username/:id/:version/release_asset_builds' => 'release_assets#index', as: :release_asset_builds, constraints: {version: VERSION_PATTERN}
      get 'assets/:username/:id/:version/:platform/:arch/release_asset' => 'release_assets#show', as: :release_asset, constraints: {version: VERSION_PATTERN}

      resources :tags, only: [:index]
    end
  end

  get 'assets-directory' => 'extensions#directory', as: 'extensions_directory'
  get "assets-collections" => 'extensions#collections', as: 'extensions_collections'
  get 'universe' => 'api/v1/universe#index', defaults: { format: :json }
  get 'status' => 'api/v1/health#show', defaults: { format: :json }
  get 'unsubscribe/:token' => 'email_preferences#unsubscribe', as: :unsubscribe

  put 'assets/:username/:id/transfer_ownership' => 'transfer_ownership#transfer', as: :transfer_ownership
  get 'ownership_transfer/:token/accept' => 'transfer_ownership#accept', as: :accept_transfer
  get 'ownership_transfer/:token/decline' => 'transfer_ownership#decline', as: :decline_transfer

  resources :extensions, path: 'assets', only: [:index]

  scope '/assets/:username' do
    resources :extensions, path: "", constraints: proc { ROLLOUT.active?(:hosted_extensions) }, only: [] do
      resources :extension_versions, as: :versions, path: 'versions', only: [:new, :create]
    end
  end

  resources :extensions, path: "", only: [:new] do
    scope "/assets/:username" do
      resources :tiers, only: [:update], controller: :extension_tiers

      member do
        get :show
        patch :update
        get :download
        put :follow
        delete :unfollow
        put :deprecate
        delete :deprecate, action: 'undeprecate'
        put :toggle_featured
        get :deprecate_search
        post :build
        post :webhook
        put :disable
        put :enable
        put :report
        put :sync_repo
        get :sync_status
        put :select_default_version
        put :update_collection
        put :update_config_overrides
        put :privacy
      end
    end

    scope "/assets" do
      collection do
        post :create
      end
    end

    member do
      post :adoption
    end
  end

  get '/assets/:username/:extension_id/versions/:version/download' => 'extension_versions#download', as: :extension_version_download, constraints: { version: VERSION_PATTERN }
  get '/assets/:username/:extension_id/versions/:version/download_asset_definition' => 'extension_versions#download_asset_definition', as: :extension_version_download_asset_definition, constraints: { version: VERSION_PATTERN }
  get '/assets/:username/:extension_id/versions/:version' => 'extension_versions#show', as: :extension_version, constraints: { version: VERSION_PATTERN }
  delete '/assets/:username/:extension_id/versions/:version' => 'extension_versions#destroy', as: :delete_extension_version, constraints: { version: VERSION_PATTERN }
  put "/assets/:username/:extension_id/versions/:version/update_platforms" => "extension_versions#update_platforms", as: :extension_update_platforms, constraints: { version: VERSION_PATTERN }

  get '/release_assets/:username/:extension_id/:version/:platform/:arch/download' => 'release_assets#download', as: :release_asset_download, constraints: { version: VERSION_PATTERN, platform: PLATFORM_PATTERN }
  get '/release_assets/:username/:extension_id/:version/:platform/:arch/asset_file' => 'release_assets#asset_file', as: :release_asset_asset_file, constraints: { version: VERSION_PATTERN, platform: PLATFORM_PATTERN }
  get '/release_assets/:username/:extension_id/:version/:platform/:arch/sha_file' => 'release_assets#sha_file', as: :release_asset_sha_file, constraints: { version: VERSION_PATTERN, platform: PLATFORM_PATTERN }

  resources :collaborators, only: [:index, :new, :create, :destroy] do
    member do
      put :transfer
    end
  end

  resources :collections

  get '/users', to: redirect('/contributors')
  resources :users, only: [:show] do
    member do
      put :make_admin
      put :disable
      put :enable
      delete :revoke_admin
      get :followed_activity, format: :atom
    end

    collection do
      get :accessible_repos
    end

    resources :accounts, only: [:destroy]
  end

  resource :profile, controller: 'profile', only: [:update, :edit] do
    post :update_install_preference, format: :json

    collection do
      patch :change_password
      get :link_github, path: 'link-github'
    end
  end

  resources :invitations, constraints: proc { ROLLOUT.active?(:cla) && ROLLOUT.active?(:github) }, only: [:show] do
    member do
      get :accept
      get :decline
    end
  end

  resources :organizations, constraints: proc { ROLLOUT.active?(:cla) && ROLLOUT.active?(:github) }, only: [:show, :destroy] do
    member do
      put :combine

      get :requests_to_join, constraints: proc { ROLLOUT.active?(:join_ccla) && ROLLOUT.active?(:github) }
    end

    resources :contributors, only: [:update, :destroy], controller: :contributors, constraints: proc { ROLLOUT.active?(:cla) && ROLLOUT.active?(:github) }

    resources :invitations, only: [:index, :create, :update], constraints: proc { ROLLOUT.active?(:cla) && ROLLOUT.active?(:github) },
                            controller: :organization_invitations do

      member do
        patch :resend
        delete :revoke
      end
    end
  end

  resources :tiers

  get 'become-a-contributor' => 'contributors#become_a_contributor', constraints: proc { ROLLOUT.active?(:cla) && ROLLOUT.active?(:github) }
  get 'contributors' => 'contributors#index'

  get 'chat' => 'irc_logs#index'
  get 'chat/:channel' => 'irc_logs#show'
  get 'chat/:channel/:date' => 'irc_logs#show'

  # when signing in or up with chef account
  # match 'auth/chef_oauth2/callback' => 'sessions#create', as: :auth_session_callback, via: [:get, :post]
  match 'auth/github/callback' => 'sessions#create', as: :auth_session_callback, via: [:get, :post]

  get 'auth/failure' => 'sessions#failure', as: :auth_failure
  get 'login'   => redirect('/sign-in'), as: nil
  get 'signin'  => redirect('/sign-in'), as: nil
  get 'sign-in' => 'sessions#new', as: :sign_in
  get 'sign-up' => 'sessions#new', as: :sign_up

  delete 'logout'   => redirect('/sign-out'), as: nil
  delete 'signout'  => redirect('/sign-out'), as: nil
  delete 'sign-out' => 'sessions#destroy', as: :sign_out

  # when linking an oauth account
  match 'auth/:provider/callback' => 'accounts#create', as: :auth_callback, via: [:get, :post]

  # this is what a logged in user sees after login
  get 'dashboard' => 'pages#dashboard'
  get 'robots.:format' => 'pages#robots'
  root 'extensions#directory'

  constraints lambda { |r| AuthConstraint.is_admin?(r) } do
    mount Sidekiq::Web => "/sidekiq"
  end

end

class AuthConstraint
  def self.is_admin?(request)
    return false unless (user_id = request.session[:user_id])
    return User.find_by(id: user_id).is?(:admin) rescue false
  end
end
