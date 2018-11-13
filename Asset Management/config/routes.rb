Rails.application.routes.draw do
  mount EpiCas::Engine, at: '/'
  devise_for :users

  resources :categories, except: :show do
    get 'filter', on: :collection
    post 'new_peripheral', on: :member
  end

  resources :users do
    get 'manager', on: :collection
  end

  resources :user_home_categories, except: %i[show edit update]

  resources :combined_bookings, only: [] do
    member do
      put 'set_booking_rejected'
      put 'set_booking_accepted'
      put 'set_booking_returned'
      put 'set_booking_cancelled'
    end
  end

  resources :bookings, except: %i[new show] do
    collection do
      get 'requests'
      get 'accepted'
      get 'ongoing'
      get 'completed'
      get 'rejected'
      get 'late'
    end

    member do
      get 'booking_returned'
      put 'set_booking_rejected'
      put 'set_booking_accepted'
      put 'set_booking_returned'
      put 'set_booking_cancelled'
    end
  end

  resources :items do
    resources :bookings, except: %i[index show] do
      collection do
        get 'start_date'
        get 'end_date'
        get 'peripherals'
      end
    end

    collection do
      get 'import'
      post 'import_file'
      get 'manager'
      put 'update_manager_multiple'
      post 'change_manager_multiple'
      put 'update_manager_multiple_and_delete'
      get 'change_manager_multiple_and_delete'
    end

    member do
      get 'add_peripheral_option'
      get 'choose_peripheral'
      post 'add_peripheral'
      get 'add_parents'
      post 'add_parents_complete'
    end
  end

  resources :notifications, only: :index do
    put :mark_as_read, on: :collection
  end

  root to: 'home#index'

  match '/403', to: 'errors#error_403', via: :all
  match '/404', to: 'errors#error_404', via: :all
  match '/422', to: 'errors#error_422', via: :all
  match '/500', to: 'errors#error_500', via: :all

  get :ie_warning, to: 'errors#ie_warning'
  get :javascript_warning, to: 'errors#javascript_warning'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
