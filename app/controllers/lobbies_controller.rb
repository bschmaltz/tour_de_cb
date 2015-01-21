class LobbiesController < ApplicationController
  protect_from_forgery with: :exception

  def view
    @lobbies = Lobby.where("id IS NOT NULL").paginate(page: params[:page], per_page: 25)
    @player_count = []

    @lobbies.each do |lobby|
      @player_count.push(User.where("lid = ?", lobby.id).count)
    end
  end

  def search
    @min = Integer(params[:search][:min])
    if params[:search][:name]!="" && params[:search][:name]!=nil
      @lobbies = Lobby.where("name = ?", params[:search][:name])
    end

    @player_count = []
    @lobbies.each do |lobby|
      @player_count.push(User.where("lid = ?", lobby.id).count)
    end
  end

  def new
  end

  def create
    lobby = Lobby.create params.require(:new_lobby).permit(:name, :map, :limit)
    lobby.host = session[:user][:email]
    if lobby.save
      redirect_to :controller => 'game', :action => 'gamemode', :id => lobby.id, :create => 'true'
    else
      flash[:fail] = "Your #{lobby.errors.keys.first} #{lobby.errors.values.first[0]}."

      redirect_to :new_lobby
    end
  end
end
