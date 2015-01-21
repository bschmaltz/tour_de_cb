class RaceController < WebsocketRails::BaseController
  #called by default when websocket is created
  def initialize_session
    puts 'initialize_session called: socket opened'
  end

  #a user has connected
  def initiate_session
    puts "starting intitiate session...."
    user = User.find_by(email: session[:user][:email])
    lobby= Lobby.find_by id: user.lid
    race = Race.where("lid = ? AND end_time is ?", lobby.id, nil).first
    dist = 0
    lastUpdate=nil

    if race!=nil
      if CurrentRaceUpdate.where("uid = ? AND rid = ?", user.id, race.id).count()>0
        lastUpdate = CurrentRaceUpdate.where("uid = ? AND rid = ?", user.id, race.id).order("created_at").last()
      end
      if lastUpdate!=nil
        dist=lastUpdate.distance
        CurrentRaceUpdate.create(uid: user.id, rid: race.id, distance: lastUpdate.distance, game_time: Time.now()-race.created_at, speed: 0)
      else
        CurrentRaceUpdate.create(uid: user.id, rid: race.id, distance: 0.0, game_time: Time.now()-race.created_at, speed: 0)
      end
      user.update(race_status: "racing")
    else
      user.update(race_status: "lobby")
    end
    WebsocketRails[message[:chan]].trigger(:new_user, {email: session[:user][:email], distance: dist})
    puts "....session started channel:#{message[:chan]} user:#{session[:user][:email]}, dist=#{dist}}"
  end

  #start race
  def start
    puts "starting race...."
    user = User.find_by(email: session[:user][:email])
    lobby = Lobby.find_by id: user.lid
    chan = user.lid.to_s
    if lobby.host==user.email
      race = Race.create(lid: lobby.id)
      User.where("lid = ?", lobby.id).each do |player|
        player.update(race_status: "racing")
        CurrentRaceUpdate.create(uid: player.id, rid: race.id, distance: 0.0, game_time: 0.0, speed: 0)
      end
      WebsocketRails[chan].trigger(:start, {})
    end
    puts "....race started"
  end

  #a user has moved
  def new_distance
    puts 'new distance started....'
    user = User.find_by(email: session[:user][:email])
    lobby= Lobby.find_by id: user.lid
    race = Race.where("lid = ? AND end_time is ?", lobby.id, nil).first
    chan = user.lid.to_s
    #check if user moved in active race
    if message[:update_distance]>=0 && race!=nil
      #check if user already finnished
      if user.race_status!="finished"
        #store their movement and check if they finnished
        lastUpdate = CurrentRaceUpdate.where("uid = ? AND rid = ?", user.id, race.id).order("created_at").last()
        new_distance = message[:update_distance]+lastUpdate.distance
        time = Time.now()-race.created_at
        CurrentRaceUpdate.create(uid: user.id, rid: race.id, distance: new_distance, game_time: time, speed: (((new_distance-lastUpdate.distance)/(time-(lastUpdate.game_time || 0))*223.694).round)/100)
        end_dist = 100

        if lobby.map=='Demo'
          end_dist = 2137
        elsif lobby.map=='First Map'
          end_dist = 101640
        elsif lobby.map=='Merica'
          end_dist = 3534480
        elsif lobby.map=='Time Square'
          end_dist = 17949
        end

        #clear up some data if there are more than 20 stored updates
        #delete half the elements
        updates = CurrentRaceUpdate.where("uid = ? AND rid = ?", user.id, race.id).order("created_at")
        if updates.count>21
          r=1
          updates.each do |an_update|
            if r==21 || r==20 || r==18 || r==15 || r==10 || r==1
              an_update.delete
            end
            r=r+1
          end
        end

        if new_distance>=end_dist
          #if they finnished - update their status, store their race summary, and show then clear their data for this race
          user.update(race_status: "finished")
          place = RaceSummary.where("rid = ? AND place != ?", race.id, 0).count+1
          miles_travelled = end_dist*0.000621371192
          cb = ((82 * miles_travelled) * (time/3600)).round
          #check if racesummary already exsists (they left race earlier)
          raceSum = RaceSummary.where("uid = ? AND rid = ?", user.id, race.id)
          if raceSum.count==0
            RaceSummary.create(uid: user.id, rid: race.id, place: place, time: time, distance: miles_travelled, calories: cb, map: lobby.map)
          else
            raceSum.first.update(place: place, time: time, distance: miles_travelled, calories: cb)
          end
          #send race data to be displayed to client
          WebsocketRails[chan].trigger(:new_distance, {email: session[:user][:email], distance: end_dist, done: place, time: time, calories: cb, points: CurrentRaceUpdate.where("uid = ? AND rid = ?", user.id, race.id).order("created_at ASC")})
        else
          #user is not done, just update position
          #get standings
          num_done = RaceSummary.where("rid = ? AND place != ?", race.id, 0).count
          racer_distances = CurrentRaceUpdate.where(race.id).group("uid").maximum("distance").sort_by{|k,v| v}
          standings = []
          p=1+num_done
          i=racer_distances.length-1
          while i>=0 do
            User.where("lid = ? AND race_status = ?", lobby.id, 'racing').select("id, email").each do |racer|
              if racer.id==racer_distances[i][0]
                standings.push([racer.email, p])
                p=p+1
              end
            end
            i=i-1
          end
        	WebsocketRails[chan].trigger(:new_distance, {email: session[:user][:email], distance: new_distance, done: 0, update_distance: message[:update_distance], update_time: Time.now-lastUpdate.created_at, game_time: time, standings: standings})
        end
      end
      #check if everyone finnished, end race and restart lobby
      if User.where("lid = ? AND race_status = ?", lobby.id, 'finished').count == User.where("lid = ?", lobby.id).count
        race.update(end_time: Time.now)
        CurrentRaceUpdate.delete_all("rid=#{race.id}")
        User.where("lid = ?", lobby.id).each do |player|
          player.update(race_status: "lobby")
        end
        WebsocketRails[chan].trigger(:restart, {finishes: RaceSummary.where("rid = ?", race.id).limit(16).order("place").select('users.email, race_summaries.*').joins('INNER JOIN users ON users.id = race_summaries.uid')})
      end
    end
    puts '....new distance ended'
  end

  #a user has left
  def terminate_session
    puts "starting termination...."
  	user = User.find_by(email: session[:user][:email])
    lobby = Lobby.find_by id: user.lid
    chan = user.lid.to_s

    user.update(race_status: "not in lobby", lid: nil)
    #check if lobby is empty
    if User.where("lid = ?", lobby.id).count==0
      #lobby has 0 players now, so we delete it
      lobby.delete()
    #check if host has left (other players are still in game)
    elsif session[:user][:email]==lobby.host
      #select new host for lobby
      new_host = User.where("lid = ? AND email != ?", lobby.id, user.email).first.email
      lobby.update(host: new_host)
      WebsocketRails[chan].trigger(:new_host, {new_host_name: new_host})
    end
    
    race = Race.where("lid = ? AND end_time is ?", lobby.id, nil).first()
    #if user was in race, store progress
    if race!=nil
      lastUpdate = CurrentRaceUpdate.where("uid = ? AND rid = ?", user.id, race.id).order("created_at").last()
      dist = lastUpdate.distance
      raceSum = RaceSummary.where("uid = ? AND rid = ?", user.id, race.id)
      time = Time.now-race.created_at
      cb = ((82*dist*0.000621371192)*(time/3600)).round
      if raceSum.count==0
        RaceSummary.create(uid: user.id, rid: race.id, place: 0, time: time, distance: dist*0.000621371192, calories: cb, map: lobby.map)
      else
        if raceSum.first().place==0
          raceSum.first().update(time: Time.now-race.created_at, distance: dist*0.000621371192, calories: cb)
        end
      end
      
      #if they were last racer, end race and restart lobby
      if User.where("lid = ? AND race_status = ?", lobby.id, 'racing').count==0
        race.update(end_time: Time.now)
        CurrentRaceUpdate.delete_all("rid=#{race.id}")
        User.where("lid = ?", lobby.id).each do |player|
          player.update(race_status: "lobby")
        end
        WebsocketRails[chan].trigger(:restart, {finishes: RaceSummary.where("rid = ?", race.id).limit(16).order("place").select('users.email, race_summaries.*').joins('INNER JOIN users ON users.id = race_summaries.uid')})
      end
    end

    #remove user from lobby
    WebsocketRails[message[:chan]].trigger(:dc_user, {email: session[:user][:email], host_name: lobby.host})
    puts "....terminate session channel:#{message[:chan]} user:#{session[:user][:email]}"
  end

  #host ends race
  def end
    puts "ending race...."
    user = User.find_by(email: session[:user][:email])
    lobby = Lobby.find_by id: user.lid
    chan = user.lid.to_s
    race = Race.where("lid = ? AND end_time is ?", lobby.id, nil).first()

    #sanity check that this is host and he/she is in a race
    if lobby.host == session[:user][:email] && race!=nil
      User.where("lid = ?", lobby.id).each do |player|
        #for people still racing, save their summary
        if player.race_status=='racing'
          lastUpdate = CurrentRaceUpdate.where("uid = ? AND rid = ?", user.id, race.id).order("created_at").last()
          dist = lastUpdate.distance
          raceSum = RaceSummary.where("uid = ? AND rid = ?", player.id, race.id)
          time = Time.now-race.created_at
          cb = ((82*dist*0.000621371192)*(time/3600)).round
          if raceSum.count==0
            RaceSummary.create(uid: player.id, rid: race.id, place: 0, time: time, distance: dist*0.000621371192, map: lobby.map, calories: cb)
          else
            raceSum.first.update(time: time, distance: dist*0.000621371192, calories: cb)
          end
        end 
        #all players moved to the lobby
        player.update(race_status: "lobby")
      end
      #end race, restart lobby
      race.update(end_time: Time.now)
      CurrentRaceUpdate.delete_all("rid=#{race.id}")
      WebsocketRails[chan].trigger(:restart, {finishes: RaceSummary.where("rid = ?", race.id).limit(16).order("place").select('users.email, race_summaries.*').joins('INNER JOIN users ON users.id = race_summaries.uid')})
    end
    puts "....race ended"
  end

  def chat_message
    if !message[:text].blank?
      user = User.find_by(email: session[:user][:email])
      chan = user.lid.to_s
      WebsocketRails[chan].trigger(:new_mes, {sender: session[:user][:email], message_text: message[:text]})
    end
  end

  def edit_map
    puts "editing map...."
    user = User.find_by(email: session[:user][:email])
    lobby = Lobby.find_by id: user.lid
    chan = user.lid.to_s
    race = Race.where("lid = ? AND end_time is ?", lobby.id, nil).count()

    #check if it's host, lobby isn't racing, and it's a different map
    if lobby.host == session[:user][:email] && race==0 && lobby.map!=message[:map]
      lobby.update(map: message[:map])
      WebsocketRails[chan].trigger(:change_map, {new_map: message[:map]})
    end
    puts "....map edited"
  end

  def edit_max
    puts "editing max...."
    user = User.find_by(email: session[:user][:email])
    lobby = Lobby.find_by id: user.lid
    chan = user.lid.to_s
    race = Race.where("lid = ? AND end_time is ?", lobby.id, nil).count()
    player_count = User.where("lid = ?", lobby.id).count()

    #check if it's host, lobby isn't racing, and new max is higher than current player count
    if lobby.host == session[:user][:email] && race==0 && player_count<=message[:max] && message[:max]!=lobby.limit
      lobby.update(limit: message[:max])
      WebsocketRails[chan].trigger(:change_max, {new_max: message[:max]})
    end
    puts "....max edited"
  end
end