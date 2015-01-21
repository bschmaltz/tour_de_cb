class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def index
  	if !session[:user].nil?
      redirect_to :view_lobbies
    end
  end

  def about
  end

  def help
  end
end
