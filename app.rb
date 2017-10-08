# encoding: utf-8
I18n.available_locales= [:es, :en]

module API
  class V1 < Sinatra::Base

    # set :environment, :production
    set :root, ENV['app_root']

    require_relative 'config/boot.rb'

    [:controllers, :lib, :helpers, :models].each do |folder|
      Dir["#{ENV['app_root']}/#{folder}/**/*.rb"].each do |f|
        require "#{f}"
      end
    end

    register Auth

    register Sinatra::ConfigFile
    register Sinatra::JSON
    register Sinatra::Namespace

    Dir["#{ENV['app_root']}/config/*.yml"].each do |f|
      config_file f
    end

    def self.bootstrap
      initializers = "#{ENV['app_root']}/initializers/*.rb"
      Dir[initializers].each do |f|
        service = f[/([\w]+).rb/, 1]
        require "#{f}" if Config.enabled?(service)
      end

      Mongoid.raise_not_found_error = false
      Mongoid.configure do |config|
        config.sessions = settings.mongoid[:sessions]
      end
    end

    configure do
      self.bootstrap
      Stream.configure('http://127.0.0.1/stream/publish', ENV['SERVER_NAME']);
    end

    before do
      response.headers['Access-Control-Allow-Origin'] = '*'
    end

    get '/' do
      json({version: VERSION})
    end

    get '/ping' do
      Stream.publish(:api, :ping, {version: VERSION}).body
    end

    # get '/test' do
    #   track = Spotify.track_for('5HQAZ4yJEli9jb55084U9N')
    #   Api::Stream.publish(:listens, :track, track)
    #   json track
    # end


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
      json({message: Config.messages[:privacy]})
    end

    get '/terms' do
      json({message: Config.messages[:terms]})
    end

    get '/support' do
      json({message: Config.messages[:support]})
    end


    not_found do
      status 404
      json({error: 'Not found'})
    end

    error Error do
      err = env['sinatra.error']
      status err.http_code
      json(err.to_json)
    end

    error do
      status 500
      err = env['sinatra.error']
      json({error: err.message, backtrace: err.backtrace})
    end

  end
end
