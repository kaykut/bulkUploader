BulkUploader::Application.routes.draw do
  
  resources :orders

  get 'users/login'
  post 'users/login'
  
  get 'whatelse/get_started'
  get 'whatelse/error'
  get 'whatelse/download'
  
  get 'orders/index'
  get 'line_items/index'
  
  # get 'companies/sync_from_dfp'
  # get 'companies/sync_to_dfp'
  get 'companies/index'
  get 'companies/clear_all'
  get 'companies/download_all'
  get 'companies/copy_from_dfp'
  resources :companies do
    get 'show', :on => :member
  end

  # resources :companies

  # get 'labels/sync_from_dfp'
  # get 'labels/sync_to_dfp'
  get 'labels/index'
  get 'labels/clear_all'
  get 'labels/download_all'
  get 'labels/copy_from_dfp'
  resources :labels do
    get 'show', :on => :member
  end

  # resources :labels

  # get 'ad_units/sync_from_dfp'
  # get 'ad_units/sync_to_dfp'
  get 'ad_units/index'
  get 'ad_units/clear_all'
  get 'ad_units/download_all'
  get 'ad_units/copy_from_dfp'
  resources :ad_units do
    get 'show', :on => :member
  end

  get 'uploads/clear_all'
  resources :uploads do
    get 'download_errors', :on => :member
    get 'download_created', :on => :member
    get 'download_not_created', :on => :member    
  end
  # resources :uploads
    
  root :to => 'whatelse#get_started'
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end

