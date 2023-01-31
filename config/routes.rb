Rails.application.routes.draw do

  resources :company_profiles
  resources :monitoring_kanbans
  resources :supplier_ap_recaps do
    get :export, on: :collection
  end
  resources :supplier_ap_summaries do
    get :export, on: :collection
  end
  resources :customer_ar_summaries do
    get :export, on: :collection
  end
  resources :employee_time_off_requests
  resources :colors
  resources :supplier_payment_methods
  resources :employee_sections
  resources :generals
  resources :equipment
  resources :consumables
  resources :delivery_drivers
  resources :delivery_cars
  resources :internal_transfers do 
      member do
        patch :approve
        put :approve

        put :print
      end
  end
  resources :inventory_adjustments do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :import, on: :collection
    post :import, on: :collection
    get :export, on: :collection
  end

  resources :user_permissions
  resources :meeting_minutes

  resources :job_categories
  resources :job_list_reports
  resources :job_lists
  
  resources :units
  resources :employee_internships
  resources :employee_internship_contracts
  resources :sales_orders do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end
  resources :delivery_order_suppliers do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end
  resources :delivery_orders do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end
  
  resources :cost_project_finances, only: [:index, :export, :print] do 
    get :print, on: :collection
    get :export, on: :collection
  end
  resources :production_order_material_costs, only: [:index, :export, :show] do 
    get :export, on: :collection
  end
  resources :temporary_inventories, only: [:index, :export, :show] do 
    get :export, on: :collection
  end
  resources :inventories, only: [:index, :export, :show] do 
    get :export, on: :collection
  end
  resources :direct_labor_workers do 
    get :export, on: :collection
  end
  resources :direct_labor_prices do 
    member do
      patch :approve
      put :approve
    end
    get :export, on: :collection
  end
  resources :direct_labors do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end
  resources :purchase_order_suppliers do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end
  resources :outstanding_pdms, only: [:index, :export, :show] do 
    get :export, on: :collection
  end
  resources :outstanding_purchase_requests, only: [:index, :export, :show] do 
    get :export, on: :collection
  end
  resources :outstanding_purchase_order_suppliers, only: [:index, :export, :show] do 
    get :export, on: :collection
  end
  resources :quotation_suppliers
  resources :pdms do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end
  resources :purchase_requests do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end
  resources :invoice_suppliers do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end
  resources :payment_request_suppliers do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end

  resources :payment_suppliers do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end
  resources :supplier_tax_invoices do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end
  resources :invoice_supplier_receivings do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end


  resources :invoice_customers do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end
  resources :invoice_customer_price_logs do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end
  resources :customer_tax_invoices do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end
  resources :payment_customers do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end
  resources :template_banks do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end
  resources :tax_rates do
    get :export, on: :collection
  end
  resources :bill_of_materials do
    get :export, on: :collection
  end
  resources :materials do
    get :export, on: :collection
  end
  resources :products do
    get :export, on: :collection
  end
  resources :product_item_categories
  resources :product_categories
  resources :product_sub_categories
  resources :product_types
  resources :customers do
    get :export, on: :collection
  end
  resources :suppliers do 
    get :export, on: :collection
  end
  resources :positions
  resources :departments  
  resources :spreadsheet_reports  
  resources :pdf_coordinates   do 
      member do
        put :print
      end
  end
  resources :employees do
    get :export, on: :collection
  end
  resources :employee_contracts do
    get :export, on: :collection
  end

  resources :production_orders do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end
  resources :shop_floor_orders do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end
  resources :product_receivings do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end
  resources :sterilization_product_receivings do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end
  resources :shop_floor_order_sterilizations do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end
  resources :material_additionals do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end
  resources :material_returns do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end
  resources :material_receivings do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end
  resources :material_check_sheets do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end
  resources :material_outgoings do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end
  resources :finish_good_receivings do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end
  resources :semi_finish_good_receivings do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end
  resources :semi_finish_good_outgoings do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end
  resources :picking_slips do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end
  resources :rejected_materials do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end
  resources :vehicle_inspections do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end
  resources :outgoing_inspections do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end
  resources :general_receivings do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end

  resources :consumable_receivings do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end
  resources :equipment_receivings do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end
  
  resources :virtual_receivings do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end
  resources :employee_absences do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end

  resources :routine_costs do 
    member do
      patch :approve
      put :approve
    end
    get :export, on: :collection
  end

  resources :routine_cost_payments do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end

  resources :routine_cost_payment_open_prints do 
    member do
      patch :approve
      put :approve
    end
    get :export, on: :collection
  end

  resources :cash_submissions do 
    member do
      patch :approve
      put :approve
    end
    get :export, on: :collection
  end

  resources :cash_settlements do 
    member do
      patch :approve
      put :approve
    end
    get :export, on: :collection
  end
  
  resources :proof_cash_expenditures do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end

  resources :proof_cash_expenditure_open_prints do 
    member do
      patch :approve
      put :approve
    end
    get :export, on: :collection
  end

  resources :department_hierarchies do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end

  resources :list_external_bank_accounts do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end
  resources :list_internal_bank_accounts do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end
  resources :voucher_payments do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end
  resources :voucher_payment_receivings do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end

  resources :proforma_invoice_customers do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end
  
  resources :employee_leaves do 
    get :export, on: :collection
  end


  resources :schedules do 
    get :export, on: :collection
  end

  resources :employee_schedules do 
    member do
      post :upload
    end
    get :export, on: :collection
  end

  resources :employee_presences do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end

  resources :employee_overtimes do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end

  resources :working_hour_summaries do 
    member do
      patch :approve
      put :approve

      put :print
    end
    get :export, on: :collection
  end

  resources :invoice_tools do 
    # get :export, on: :collection
  end


  resources :master_files do 
    # get :export, on: :collection
  end
  
	devise_for :users, controllers: { sessions: 'users/sessions', registrations: 'users/registrations', passwords: 'users/passwords' }   
  devise_scope :user do
    get '/users', to: 'users/accounts#index'
    get '/edit-user/:id', to: 'users/accounts#edit'
    post '/upload_signature', to: 'users/accounts#upload_signature'

    post '/update-user/:id', to: 'users/accounts#update'

    get '/new_user', to: 'users/registrations#new'
   	# get ':username/edit-profile' => 'users/registrations#edit', :as => :edit_user_profile

    get '/forgot_password', to: 'users/passwords#new'
    get '/unlock', to: 'users/unlocks#new'
    get 'sign_in', to: 'users/sessions#new'
    get '/users/sign_out' => 'users/sessions#destroy'
  end
  resources :dashboards
  root to: 'dashboards#index'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end