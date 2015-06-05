# encoding: utf-8
I18n.available_locales= [:es, :en]

class API < Sinatra::Base

  # set :environment, :production
  set :root, ENV['app_root']

  require_relative 'config/boot.rb'

  [:controllers, :lib, :helpers, :models].each do |folder|
    Dir["#{ENV['app_root']}/#{folder}/**/*.rb"].each do |f|
      require "#{f}"
    end
  end

  register Sinatra::ConfigFile
  register Sinatra::JSON
  register Sinatra::Namespace
  # register SSE

  Dir["#{ENV['app_root']}/config/*.yml"].each do |f|
    config_file f
  end

  def self.bootstrap
    set :facebook, Koala::Facebook::API.new(Api::Config.facebook_access_token)
    set :facebook_oauth, Koala::Facebook::OAuth.new(Api::Config.facebook_id, Api::Config.facebook_secret)

    client = SimpleSpotify::Client.new Api::Config.spotify_key, Api::Config.spotify_secret
    client.session = SimpleSpotify::Authorization.new(
      access_token: Api::Config.spotify_token,
      refresh_token: Api::Config.spotify_refresh,
      client: client
    )
    set :spotify_client, client

    client.session.on_refresh do |sess|
      Api::Config.spotify_token = sess.access_token
      Api::Config.save
    end

    Mongoid.raise_not_found_error = false
    Mongoid.configure do |config|
      config.sessions = settings.mongoid[:sessions]
    end
  end


  configure do
    self.bootstrap
  end


  before do
    response.headers['Access-Control-Allow-Origin'] = '*'
  end

  get '/' do
    json({version: Api::VERSION})
  end


  # get '/test' do
  #   last = Event::Listen.last_event_time
  #   body = {entry: [
  #     start_time: Time.now.to_s
  #   ]}.to_json
  #   query = ['/me/music.listens', since: last.to_i]
  #   # si tan solo `since` jalara en este endpoint...

  #   tracks = []
  #   playlist = SimpleSpotify.default_client.playlist(Api::Config.spotify_user, Api::Config.spotify_playlist) rescue nil

  #   Event::Facebook.process(body, query) do |event, time|
  #     next unless time > last
  #     track = Spotify.track_for(event['song']['url'])
  #     tracks << track
  #     attrs = track.attributes

  #     evt = {
  #       track: track.id,
  #       album: attrs['album_id'],
  #       genre: attrs['genre_id'],
  #       artist: attrs['artist_id'],
  #       source: 'spotify',
  #       time: time
  #     }
  #     Event::Listen.create(evt)

  #     puts track.inspect
  #     if playlist
  #       max = Api::Config.spotify_max_tracks.to_i
  #       begin
  #         if playlist.tracks.total >= max
  #           extra = (playlist.tracks.total - max)
  #           playlist.remove_tracks(positions: (0..extra).to_a)
  #         end
  #         playlist.add_tracks(track.spotify_id)
  #       rescue Exception => e
  #         puts e
  #       end
  #     end
  #   end

  #   json tracks
  # end


  get '/privacy' do
    json({message: 'Rob no hará cosas malas con los datos de Rob, porqué es la misma persona'})
  end

  get '/terms' do
    json({message: 'Al usar este API aceptas que no va a funcionar si no quiero que funcione, y se provee AS-IS'})
  end

  get '/support' do
    json({message: 'Busca a @unRob en twitter, pero no creo que te ayude'})
  end


  not_found do
    status 404
    json({error: 'Not found'})
  end

  error Api::Error do
    err = env['sinatra.error']
    status err.http_code
    json(err.to_json)
  end

  error do
    status 500
    err = env['sinatra.error']
    json({error: err.message})
  end

end