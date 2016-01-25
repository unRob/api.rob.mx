Instagram.configure do |config|
  config.client_id = API::Config.instagram[:id]
  config.client_secret = API::Config.instagram[:secret]
end