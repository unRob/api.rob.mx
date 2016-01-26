twitter = Twitter::REST::Client.new do |config|
    config.consumer_key        = API::Config.twitter[:key]
    config.consumer_secret     = API::Config.twitter[:secret]
    config.access_token        = API::Config.twitter[:token]
    config.access_token_secret = API::Config.twitter[:access_token]
end
API::V1.set :twitter, twitter