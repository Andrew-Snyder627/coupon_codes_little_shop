Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  # Defines the root path route ("/")
  # root "posts#index"

  namespace :api do
    namespace :v1 do

      # Merchants
      resources :merchants do
        resources :customers, only: [:index], controller: "merchants_customers"
        resources :invoices, only: [:index]
        resources :items, only: [:index]
        resources :items, only: [:index], controller: "merchant_items", as: "merchant_items"
      end

      # Items
      resources :items
      get "items/find", to: "items_search#find"
      get "items/find_all", to: "items_search#find_all"
      get "items/:id/merchant", to: "item_merchants#show"

      # Coupons
      namespace :merchant_coupons do
        resources :merchants, only: [] do
          resources :coupons, only: [:index, :show, :create, :update]
        end
      end

      # Non-RESTful merchant search
      get "merchants/find", to: "merchants#find"
    end
  end
end
