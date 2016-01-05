namespace :strava do

  desc "Descarga actividades nuevas de Strava"
  task :poll => :bootstrap do |task, args|
    @client = Strava::Api::V3::Client.new(access_token: API::Config.strava[:token])
    last_ride = Ride.all.sort(started: 1).first
    opts = {per_page: 100}
    opts[:before] = last_ride.started.to_i if last_ride
    activities = @client.list_athlete_activities opts

    puts activities.count

    activities.each do |activity|
      next unless Ride.where(strava_id: activity['id']).first.nil?
      started  = Time.parse(activity['start_date'])
      ended = started+activity['elapsed_time']

      distance = activity['distance']
      mt = activity['moving_time']
      eg = activity['total_elevation_gain']

      details = @client.retrieve_an_activity(activity['id'])

      # puts JSON.pretty_generate activity
      # puts JSON.pretty_generate details
      # exit

      coords = Polylines::Decoder.decode_polyline(details['map']['polyline'])
      coords.map {|latlng| latlng.reverse }
      # puts JSON.pretty_generate coords
      # exit

      commute = details['commute']

      if details['description']
        description = details['description'].squish.split ' '
        description = description.map {|pz|
          k,v = pz.split(':')
          [k.to_sym, v]
        }.to_h

        commute = true if description[:por] == 'commute'
      end

      ride = {
        strava_id: activity['id'],
        name: activity['name'],
        started: started,
        ended: ended,
        elevation: eg,
        moved_for: mt,
        distance: distance,
        max_speed: activity['max_speed']*3.6,
        avg_speed: activity['average_speed']*3.6,
        commute: commute,
        track: {
          type: "LineString",
          coordinates: coords
        }
      }

      # final = ride.dup
      # final.delete(:track)
      # puts JSON.pretty_generate(final)


      r = Ride.create(ride)
      puts r.name
    end
  end

end