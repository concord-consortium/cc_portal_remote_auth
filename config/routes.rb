Rails.application.routes.draw do
  devise_scope :user do
    post '/remote_login', :to => 'sessions#create', :as => :remote_login
    post '/remote_logout', :to => 'sessions#destroy', :as => :remote_logout
  end
  get '/verify_cc_token', :to => 'remote_auth#verify_cc_token', :as => :verify_cc_token
end
