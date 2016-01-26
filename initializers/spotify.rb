client = SimpleSpotify::Client.new(
  API::Config.spotify[:key],
  API::Config.spotify[:secret]
)

client.session = SimpleSpotify::Authorization.new(
  access_token: API::Config.spotify[:token],
  refresh_token: API::Config.spotify[:refresh],
  client: client
)
API::V1.set :spotify_client, client

client.session.on_refresh do |sess|
  API::Config.spotify[:token] = sess.access_token
  API::Config.save
end