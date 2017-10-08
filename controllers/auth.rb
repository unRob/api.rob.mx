class API::V1 < Sinatra::Base
  register Sinatra::Namespace
  namespace '/auth' do

    get '/facebook/:secret' do |secret|
      halt(403) if API::Config.facebook[:verify] != secret

      id = API::Config.facebook[:id]
      secret = API::Config.facebook[:secret]
      redirect = request.url
      oauth = Koala::Facebook::OAuth.new(id, secret, redirect)

      if params[:code].nil?
        opts = {
          permissions: %w{user_actions.music}.join(',')
        }
        redirect to oauth.url_for_oauth_code(opts)
      else
        access_token = oauth.get_access_token(params[:code])
        API::Config.facebook[:access_token] = access_token
        API::Config.save
        # API::Config.facebook[:access_token]
        'yay!'
      end
    end


    get '/spotify/?:callback?' do |callback|
      halt(403) if API::Config.spotify[:token] != 'nil'

      redirect = request.url.gsub(/\?.+/, '')
      if callback == 'done'
        code = params[:code]
        begin
          auth = SimpleSpotify::Authorization.from_code code, client: SimpleSpotify.default_client, redirect: redirect
          API::Config.spotify[:token] = auth.access_token
          API::Config.spotify[:refresh] = auth.refresh_token
          API::Config.save
        rescue Exception => e
          json({cagation: e.message})
        else
          'yay!'
        end
      else
        login_url = SimpleSpotify::Authorization.login_uri redirect+'/done', SimpleSpotify.default_client, scope: 'playlist-modify-public user-read-private'
        redirect to(login_url)
      end
    end


    get '/instagram' do
      halt(403) if API::Config.instagram[:token] != 'nil'

      callback = request.url.gsub(/\?.+/, '')
      if params[:code]
        response = Instagram.get_access_token(params[:code], redirect_uri: callback)

        API::Config.instagram[:token] = response.access_token
        API::Config.save
        'yay!'
      else
        redirect Instagram.authorize_url(redirect_uri: callback)
      end
    end

  end
end
