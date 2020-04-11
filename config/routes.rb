# frozen_string_literal: true

Rails.application.routes.draw do
  resources :text_samples do
    member do
      get 'generate'
    end
  end

  root 'text_samples#index'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
