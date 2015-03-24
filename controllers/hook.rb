class API < Sinatra::Base
  register Sinatra::Namespace
  namespace '/hook' do

    get '/listen' do
      token = API::Config.facebook_verify
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
      puts last, body
      query = ['/me/music.listens', since: last.to_i]
      # si tan solo `since` jalara en este endpoint...

      Event::Facebook.process(body, query) do |event, time|
        next unless time > last
        track = Spotify.track_for(event['song']['url'])
        attrs = track.attributes

        Event::Listen.create({
          track: track.id,
          album: attrs[:album_id],
          genre: attrs[:genre_id],
          artist: attrs[:artist_id],
          source: 'spotify',
          time: time
        })
      end

      'ok'
    end #POST /music

    get '/fb-login/:secret' do |secret|
      if API::Config.facebook_verify != secret
        halt(403)
      end
      id = API::Config.facebook_id
      secret = API::Config.facebook_secret
      redirect = request.url
      oauth = Koala::Facebook::OAuth.new(id, secret, redirect)

      if params[:code].nil?
        opts = {
          permissions: %w{user_actions.music read_stream}.join(',')
        }
        redirect to oauth.url_for_oauth_code(opts)
      else
        access_token = oauth.get_access_token(params[:code])
        API::Config.facebook_access_token = access_token
        API::Config.save
        API::Config.facebook_access_token
      end
    end

  end
end

