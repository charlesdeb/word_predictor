Rails.application.routes.draw do
  resources :text_samples

  root 'text_samples#index'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
