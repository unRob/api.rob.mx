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
    RSpotify.authenticate Api::Config.spotify_key, Api::Config.spotify_secret

    Mongoid.raise_not_found_error = false
    Mongoid.configure do |config|
      config.sessions = settings.mongoid[:sessions]
    end
  end


  configure do
    self.bootstrap
  end

#   get '/test' do
#     <<-STR
#     <div id="messages"></div>

#     <script>
#       var source = new EventSource('/stream/listens');

#       source.addEventListener('listens', function(evt) {
#         console.log(evt);
#       }, false);
#     </script>
# STR
#   end

#   get '/publish' do
#     publish :listens, {a: 'b'}
#     'ok!'
#   end

  before do
    response.headers['Access-Control-Allow-Origin'] = '*'
  end

  not_found do
    status 404
    json({error: 'Not found'})
  end

  error ApiError do
    err = env['sinatra.error']
    status err.http_code
    json(err.to_json)
  end

  error do
    status 500
    err = env['sinatra.error']
    json({error: err.message})
  end

  # routes.each do |verb, paths|
  #   paths.each do |route|
  #     route = route[0].source.gsub(/\\[Az]/, '')
  #     puts "#{verb} #{route}"
  #   end
  # end

end