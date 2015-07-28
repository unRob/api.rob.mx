namespace :strava do

  desc "Descarga actividades nuevas de Strava"
  task :poll => :bootstrap do |task, args|
    @client = Strava::Api::V3::Client.new(access_token: Api::Config.strava[:token])
    last_ride = Event::Ride.last_event_time
    activities = @client.list_athlete_activities after: last_ride

    activities.each do |activity|
      started  = Time.parse(activity['start_date'])
      ended = started+activity['elapsed_time']

      distance = activity['distance']
      mt = activity['moving_time']
      eg = activity['total_elevation_gain']

      details = @client.retrieve_an_activity(activity['id'])

      # puts JSON.pretty_generate activity
      # puts JSON.pretty_generate details

      coords = Polylines::Decoder.decode_polyline(details['map']['polyline'])
      coords.map {|latlng| latlng.reverse }

      description = details['description'].squish.split ' '
      description = description.map {|pz|
        k,v = pz.split(':')
        [k.to_sym, v]
      }.to_h

      riders = nil
      places = nil
      razon = 'nomás'

      riders = description[:con].split(',') if description[:con]
      razon = description[:por] if description[:por]
      places = description[:en].split(',') if description[:en]


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
        reason: razon,
        track: {
          type: "LineString",
          coordinates: coords
        }
      }
      ride[:riders] = riders if riders
      ride[:places] = places if places

      final = ride.dup
      final.delete(:track)
      puts JSON.pretty_generate(final)


      # Ride.create(ride)
    end
  end

end