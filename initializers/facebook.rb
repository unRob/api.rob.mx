fbconf = API::Config.facebook
set :facebook, Koala::Facebook::API.new(fbconf[:access_token])
set :facebook_oauth, Koala::Facebook::OAuth.new(fbconf[:id], fbconf[:secret])