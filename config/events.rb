WebsocketRails::EventMap.describe do
  # You can use this file to map incoming events to controller actions.
  # One event can be mapped to any number of controller actions. The
  # actions will be executed in the order they were subscribed.
  #
  # Uncomment and edit the next line to handle the client connected event:
  #   subscribe :client_connected, :to => Controller, :with_method => :method_name
  #
  # Here is an example of mapping namespaced events:
  #   namespace :product do
  #     subscribe :new, :to => ProductController, :with_method => :new_product
  #   end
  # The above will handle an event triggered on the client like `product.new`.
  namespace :connect do
    subscribe :initiate_session, to: RaceController, with_method: :initiate_session
  end

  namespace :disconnect do
    subscribe :terminate_session, to: RaceController, with_method: :terminate_session
  end

  namespace :update_position do
    subscribe :new_distance, to: RaceController, with_method: :new_distance
  end

  namespace :new_chat_message do
    subscribe :chat_message, to: RaceController, with_method: :chat_message
  end

  namespace :start_race do
    subscribe :start, to: RaceController, with_method: :start
  end

  namespace :edit_lobby_map do
    subscribe :edit_map, to: RaceController, with_method: :edit_map
  end

  namespace :edit_lobby_max do
    subscribe :edit_max, to: RaceController, with_method: :edit_max
  end

  namespace :end_race do
    subscribe :end, to: RaceController, with_method: :end
  end
end
