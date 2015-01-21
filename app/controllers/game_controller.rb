class GameController < ApplicationController
  protect_from_forgery with: :exception

  def gamemode
    if session[:user].nil?
      redirect_to root_url
    else
      #check if game is joinable
      @lobby = Lobby.find_by id: params[:id]
      if @lobby==nil
        flash[:fail] = "Lobby no longer exists"
        redirect_to :controller => 'lobbies', :action => 'view'
      elsif User.where("lid = ?", @lobby.id).count==0 && params[:create]!='true'
        flash[:fail] = "Lobby no longer exists"
        redirect_to :controller => 'lobbies', :action => 'view'
      elsif User.where("lid = ?", @lobby.id).count>=@lobby.limit
        flash[:fail] = "Lobby is full"
        redirect_to :controller => 'lobbies', :action => 'view'
      else
        #game is joinable
        user = User.find_by(email: session[:user][:email])
        user.update(lid: params[:id])

        @user_start = 0
        @lobby_racing = false
        @user_racing = false
        @race = Race.where("lid = ? AND end_time is ?", @lobby.id, nil).first()
        if @race!=nil
          @user_racing = true
          @lobby_racing = true
          @user_start = CurrentRaceUpdate.where("rid = ? AND uid = ?", @race.id, User.find_by(email: session[:user][:email]).id).sum('distance')
          #check is user isn't already done
          summary = RaceSummary.where("uid = ? AND rid = ?", user.id, @race.id).first()
          if summary != nil && summary.place!=0
            @user_racing = false
          end
        end

        @other_players_email = []
        @other_players_start = []
        @other_players_status = []
        User.where("email != ? AND lid = ?", session[:user][:email], @lobby.id).each do |other_player|
          @other_players_email.push(other_player.email)
          if other_player.race_status=='racing'
            @other_players_status.push("racing")
            @other_players_start.push(CurrentRaceUpdate.where("rid = ? AND uid = ?", @race.id, other_player.id).sum('distance'))
          else
            @other_players_status.push("waiting")
            @other_players_start.push(0.0)
          end
        end
      end
    end
  end

  def lobbymode
  end
end
