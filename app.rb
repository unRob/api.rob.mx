# encoding: utf-8
I18n.available_locales= [:es, :en]

class API < Sinatra::Base

  set :environment, :production
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
    set :facebook, Koala::Facebook::API.new(Config.facebook_access_token)
    set :facebook_oauth, Koala::Facebook::OAuth.new(Config.facebook_id, Config.facebook_secret)
    RSpotify.authenticate Config.spotify_key, Config.spotify_secret

    Mongoid.raise_not_found_error = false
    Mongoid.configure do |config|
      config.sessions = settings.mongoid[:sessions]
    end
  end

  configure do
    self.bootstrap
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
    json({error: e.message})
  end

  # routes.each do |verb, paths|
  #   paths.each do |route|
  #     route = route[0].source.gsub(/\\[Az]/, '')
  #     puts "#{verb} #{route}"
  #   end
  # end

end