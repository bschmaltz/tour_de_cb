TourDeCb::Application.routes.draw do
  root 'application#index'
  resources :users

  get '/about', to:'application#about', as: :about
  get '/help', to:'application#help', as: :help

  get '/user/regenerate_key', to: 'users#regenerate_key', as: :regenerate_key

  post '/user/login', to: 'users#authenticate', as: :login
  get '/user/logout', to: 'users#logout', as: :logout
  post '/user/register', to: 'users#create', as: :register
  get '/user/profile', to: 'users#show', as: :profile

  get 'lobby/view', to: 'lobbies#view', as: :view_lobbies
  post 'lobby/search', to: 'lobbies#search', as: :search_lobbies
  get 'lobby/new', to: 'lobbies#new', as: :new_lobby
  post 'lobby/create', to: 'lobbies#create', as: :create_lobby
  get 'lobby/enter', to: 'lobbies#enter', as: :enter_lobby
  post  'lobby/edit', to: 'lobbies#edit', as: :edit_lobby

  get '/game/gamemode', to: 'game#gamemode', as: :gamemode

  post '/distance/:update_distance', to: 'distance#traverse', format: :json
  post '/websocket', :to => WebsocketRails::ConnectionManager.new
end
