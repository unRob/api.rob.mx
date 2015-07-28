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

  Dir["#{ENV['app_root']}/config/*.yml"].each do |f|
    config_file f
  end

  def self.bootstrap
    fbconf = Api::Config.facebook
    set :facebook, Koala::Facebook::API.new(fbconf[:access_token])
    set :facebook_oauth, Koala::Facebook::OAuth.new(fbconf[:id], fbconf[:secret])

    client = SimpleSpotify::Client.new Api::Config.spotify[:key], Api::Config.spotify[:secret]
    client.session = SimpleSpotify::Authorization.new(
      access_token: Api::Config.spotify[:token],
      refresh_token: Api::Config.spotify[:refresh],
      client: client
    )
    set :spotify_client, client

    twitter = Twitter::REST::Client.new do |config|
        config.consumer_key        = Api::Config.twitter[:key]
        config.consumer_secret     = Api::Config.twitter[:secret]
        config.access_token        = Api::Config.twitter[:token]
        config.access_token_secret = Api::Config.twitter[:access_token]
    end
    set :twitter, twitter

    client.session.on_refresh do |sess|
      Api::Config.spotify[:token] = sess.access_token
      Api::Config.save
    end

    Mongoid.raise_not_found_error = false
    Mongoid.configure do |config|
      config.sessions = settings.mongoid[:sessions]
    end
  end


  configure do
    self.bootstrap

    if ENV['SERVER_NAME']
      scheme = ENV['HTTPS'] ? 'https://' : 'http://';
      Api::Stream.configure(scheme+ENV['SERVER_NAME']+'/stream/publish');
    end
  end


  before do
    response.headers['Access-Control-Allow-Origin'] = '*'
  end

  get '/' do
    json({version: Api::VERSION})
  end

  get '/ping' do
    Api::Stream.publish(:api, :ping, {version: Api::VERSION}).body
  end

  get '/test' do
    track = Spotify.track_for('5HQAZ4yJEli9jb55084U9N')
    Api::Stream.publish(:listens, :track, track)
    json track
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