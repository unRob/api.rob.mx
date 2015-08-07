class API::V1 < Sinatra::Base
  register Sinatra::Namespace
  namespace '/hook' do

    get '/listen' do
      token = Config.facebook[:verify]
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
      body = request.body.read
      query = ['/me/music.listens', since: last.to_i]
      # si tan solo `since` jalara en este endpoint...

      puts "ping /listens"
      puts "body:\n#{body}"

      playlist = SimpleSpotify.default_client.playlist(Config.spotify_user, Config.spotify_playlist) rescue nil
      puts playlist.nil?

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

        if playlist
          max = Config.spotify_max_tracks.to_i
          begin
            if playlist.tracks.total >= max
              extra = (playlist.tracks.total - max)
              playlist.remove_tracks(positions: (0..extra).to_a)
            end
            playlist.add_tracks(track.spotify_id)
          rescue Exception => e
            puts e
          end
        end

        Stream.publish(:listens, :track, track.as_json)
      end

      puts "DONE /listens"

      'ok'
    end #POST /music


    #--------------
    # Logins
    #--------------
    get '/fb-login/:secret' do |secret|
      if Config.facebook[:verify] != secret
        halt(403)
      end
      id = Config.facebook[:id]
      secret = Config.facebook[:secret]
      redirect = request.url
      oauth = Koala::Facebook::OAuth.new(id, secret, redirect)

      if params[:code].nil?
        opts = {
          permissions: %w{user_actions.music read_stream}.join(',')
        }
        redirect to oauth.url_for_oauth_code(opts)
      else
        access_token = oauth.get_access_token(params[:code])
        Config.facebook[:access_token] = access_token
        Config.save
        # Config.facebook[:access_token]
        'yay!'
      end
    end


    get '/spotify-login/?:callback?' do |callback|
      if Config.spotify_token != 'nil'
        halt(403)
      end

      redirect = request.url.gsub(/\?.+/, '')

      if callback == 'done'
        code = params[:code]
        begin
          auth = SimpleSpotify::Authorization.from_code code, client: SimpleSpotify.default_client, redirect: redirect
          Config.spotify_token = auth.access_token
          Config.spotify_refresh = auth.refresh_token
          Config.save
        rescue Exception => e
          json({cagation: e.message})
        else
          'yay!'
        end
      else
        login_url = SimpleSpotify::Authorization.login_uri redirect+'/done', SimpleSpotify.default_client, scope: 'playlist-modify-public user-read-private'

        redirect to(login_url)
      end


    end

  end
end