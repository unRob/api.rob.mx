fbconf = API::Config.facebook
API::V1.set :facebook, Koala::Facebook::API.new(fbconf[:access_token])
API::V1.set :facebook_oauth, Koala::Facebook::OAuth.new(fbconf[:id], fbconf[:secret])