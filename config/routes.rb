# frozen_string_literal: true

Rails.application.routes.draw do
  scope "org/:org_permalink", as: "organization" do
    resources :domains, only: [:index, :new, :create, :destroy] do
      match :verify, on: :member, via: [:get, :post]
      get :setup, on: :member
      post :check, on: :member
    end
    resources :servers, except: [:index] do
      resources :domains, only: [:index, :new, :create, :destroy] do
        match :verify, on: :member, via: [:get, :post]
        get :setup, on: :member
        post :check, on: :member
      end
      resources :track_domains do
        post :toggle_ssl, on: :member
        post :check, on: :member
      end
      resources :credentials
      resources :routes
      resources :http_endpoints
      resources :smtp_endpoints
      resources :address_endpoints
      # Sender25 - Using rules instead of ip_pool_rules
      # resources :ip_pool_rules
      resources :rules
      resources :messages do
        get :incoming, on: :collection
        get :outgoing, on: :collection
        get :held, on: :collection
        get :activity, on: :member
        get :plain, on: :member
        get :html, on: :member
        get :html_raw, on: :member
        get :attachments, on: :member
        get :headers, on: :member
        get :attachment, on: :member
        get :download, on: :member
        get :spam_checks, on: :member
        # Sender25 - Added route to toggle spam status
        post :toggle_spam, on: :member
        post :retry, on: :member
        post :cancel_hold, on: :member
        # Sender25 - Removed server suppression list
        #get :suppressions, on: :collection
        delete :remove_from_queue, on: :member
        get :deliveries, on: :member
        # Sender25 - Added routes for search action buttons
        post "incoming/toggle_spam_search", on: :collection, action: "toggle_spam_search_incoming"
        post "incoming/retry_search", on: :collection, action: "retry_search_incoming"
        delete "incoming/remove_from_queue_search", on: :collection, action: "remove_from_queue_search_incoming"
        post "outgoing/toggle_spam_search", on: :collection, action: "toggle_spam_search_outgoing"
        post "outgoing/retry_search", on: :collection, action: "retry_search_outgoing"
        delete "outgoing/remove_from_queue_search", on: :collection, action: "remove_from_queue_search_outgoing"
      end
      resources :webhooks do
        get :history, on: :collection
        get "history/:uuid", on: :collection, action: "history_request", as: "history_request"
      end
      get :limits, on: :member
      get :retention, on: :member
      get :queue, on: :member
      get :spam, on: :member
      get :delete, on: :member
      get "help/outgoing" => "help#outgoing"
      get "help/incoming" => "help#incoming"
      get :advanced, on: :member
      post :suspend, on: :member
      post :unsuspend, on: :member
      # Sender25 - Added route for statistics
      resources :statistics, only: [:index]
    end
    # Sender25 - Changed route to custom rules instead of default
    # resources :ip_pool_rules
    resources :rules
    resources :ip_pools, controller: "organization_ip_pools" do
      put :assignments, on: :collection
    end

    # Sender25 - Added route to make user owner
    resources :users do
      post :make_owner, on: :member
    end
    root "servers#index"
    get "settings" => "organizations#edit"
    patch "settings" => "organizations#update"
    get "delete" => "organizations#delete"
    delete "delete" => "organizations#destroy"
  end

  resources :organizations, except: [:index]
  resources :users
  resources :ip_pools do
    resources :ip_addresses
  end

  # Sender25 - Added route for global suppression list
  resources :suppressions, only: [:index]

  get "settings" => "user#edit"
  patch "settings" => "user#update"
  post "persist" => "sessions#persist"

  get "login" => "sessions#new"
  post "login" => "sessions#create"
  get "login/token" => "sessions#create_with_token"
  delete "logout" => "sessions#destroy"
  match "login/reset" => "sessions#begin_password_reset", :via => [:get, :post]
  match "login/reset/:token" => "sessions#finish_password_reset", :via => [:get, :post]

  get "ip" => "sessions#ip"

  root "organizations#index"

  # Sender25 - Added route for blacklist toggle
  post "blacklist/toggle" => "blacklists#toggle"
end
