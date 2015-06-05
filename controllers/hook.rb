class API < Sinatra::Base
  register Sinatra::Namespace
  namespace '/hook' do

    get '/listen' do
      token = Api::Config.facebook_verify
      puts 'verificando suscripción'
      if Koala::Facebook::RealtimeUpdates.meet_challenge(params, token)
        params['hub.challenge']
      else
        'nel'
      end
    end

    post '/listen' do
      last = Event::Listen.last_event_time
      body = request.body.read
      query = ['/me/music.listens', since: last.to_i]
      # si tan solo `since` jalara en este endpoint...

      playlist = SimpleSpotify.default_client.playlist(Api::Config.spotify_user, Api::Config.spotify_playlist) rescue nil

      Event::Facebook.process(body, query) do |event, time|
        next unless time > last
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
          begin
            if playlist.tracks.total >= Api::Config.spotify_max_tracks
              extra = (playlist.tracks.total - Api::Config.spotify_max_tracks)
              playlist.remove_tracks(positions: (0..extra).to_a)
            end
            playlist.add_tracks(track.spotify_id)
          rescue Exception => e
            puts e.message
          end
        end
      end

      'ok'
    end #POST /music


    #--------------
    # Logins
    #--------------
    get '/fb-login/:secret' do |secret|
      if Api::Config.facebook_verify != secret
        halt(403)
      end
      id = Api::Config.facebook_id
      secret = Api::Config.facebook_secret
      redirect = request.url
      oauth = Koala::Facebook::OAuth.new(id, secret, redirect)

      if params[:code].nil?
        opts = {
          permissions: %w{user_actions.music read_stream}.join(',')
        }
        redirect to oauth.url_for_oauth_code(opts)
      else
        access_token = oauth.get_access_token(params[:code])
        Api::Config.facebook_access_token = access_token
        Api::Config.save
        Api::Config.facebook_access_token
      end
    end


    get '/spotify-login/?:callback?' do |callback|
      if Api::Config.spotify_token != 'nil'
        halt(403)
      end

      client_id = Api::Config.spotify_key
      redirect = request.url.gsub(/\?.+/, '')

      if callback == 'done'
        code = params[:code]
        require 'net/http'

        uri = URI.parse "https://accounts.spotify.com/api/token"
        params = {
          grant_type: 'authorization_code',
          redirect_uri: redirect,
          code: code,
          client_id: client_id,
          client_secret: Api::Config.spotify_secret
        }
        res = Net::HTTP.post_form(uri, params)
        body = JSON.parse(res.body, symbolize_names: true)

        if body[:access_token]
          Api::Config.spotify_token = body[:access_token]
          Api::Config.refresh_token = body[:refresh_token]
          Api::Config.save
        else
          json(res.body)
        end
      else
        redirect += '/done'
        redirect to("https://accounts.spotify.com/authorize?client_id=#{client_id}&response_type=code&scope=playlist-modify-public user-read-private&redirect_uri=#{redirect}&show_dialog=true")
      end


    end

  end
end