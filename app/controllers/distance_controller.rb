class DistanceController < ApplicationController
	skip_before_filter :verify_authenticity_token

  def traverse
  	user = User.find_by_secret_key(request.headers["HTTP_SECRET_KEY"])
    unless user.nil?
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
          CurrentRaceUpdate.create(uid: user.id, rid: race.id, distance: new_distance, game_time: time, speed: (((new_distance-lastUpdate.distance)/(time-lastUpdate.game_time)*223.694).round)/100)
          end_dist = 100

          if lobby.map=='Demo'
            end_dist = 2140
          elsif lobby.map=='First Map'
            end_dist = 102139
          elsif lobby.map=='Merica'
            end_dist = 3603573
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
      render json: '{"status" : "success"}'
    else
      render json: '{"status" : "failure"}'
    end
  end
end
