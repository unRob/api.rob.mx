class API::V1 < Sinatra::Base
  register Sinatra::Namespace
  namespace '/hook' do

    get '/listen' do
      token = API::Config.facebook[:verify]
      puts 'verificando suscripción'
      if Koala::Facebook::RealtimeUpdates.meet_challenge(params, token)
        puts 'validated'
        params['hub.challenge']
      else
        puts 'nel'
        'nel'
      end
    end

    post '/listen' do
      last = Event::Listen.last_event_time
      puts last
      body = request.body.read
      query = ['/me/music.listens', {limit: 100}]#, since: last.to_i]
      # si tan solo `since` jalara en este endpoint...

      puts "ping /listens"
      puts "body:\n#{body}"

      playlist = SimpleSpotify.default_client.playlist(
        API::Config.spotify[:user],
        API::Config.spotify[:playlist]
      ) rescue nil
      puts playlist.nil?

      last_track = nil
      Event::Facebook.process(body, query) do |event, time|
        unless time > last
          begin
            puts "skipping #{event['song']['url']}"
          rescue Exception
            puts "skipping"
          end
          next
        end
        puts "PROCESSING #{event['song']['url']}"
        track = Spotify.track_for(event['song']['url'])
        last_track = track
        attrs = track.attributes

        evt = {
          track: track.id,
          album: attrs['album_id'],
          genre: attrs['genre_id'],
          artist: attrs['artist_id'],
          source: 'spotify',
          time: time
        }
        Event::Listen.create(evt)
        #ENV['DEBUG'] = true
        if playlist
          max = API::Config.spotify[:max_tracks].to_i
          begin
            if playlist.tracks.total >= max
              extra = (playlist.tracks.total - max)
              playlist.remove_tracks(positions: (0..extra).to_a)
            end
            playlist.add_tracks(track.spotify_id)
          rescue Exception => e
            puts e
            puts e.code
            puts e.message
          end
        end

        API::Stream.publish(:listens, :track, track.as_json)
      end

      puts "DONE /listens"

      json last_track.as_json
    end #POST /music


    get '/instagram' do
      params['hub.challenge']
    end

    post '/instagram' do
      body = request.body
      # halt(401) unless Instagram.validate_update(body, headers)

      client = Instagram.client(access_token: API::Config.instagram[:token])
      Instagram.process_subscription(body) do |handler|
        $stderr.puts 'sub'
        handler.on_user_changed {
          $stderr.puts 'uc'
          last = Media.from_service(:instagram).sort({time: 1}).first.meta[:id]
          opts = {min_id: last}
          client.user_recent_media(opts).each do |media|
            Media.from_instagram(media)
          end
        }
      end
      "ok"
    end

  end
end
