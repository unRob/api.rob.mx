Pushover.configure do |config|
  config.user  = API::Config.pushover[:user]
  config.token = API::Config.pushover[:token]
end