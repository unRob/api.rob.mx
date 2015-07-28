class API < Sinatra::Base
  register Sinatra::Namespace
  namespace '/twitter' do

    get '/last' do
      json Tweet.last_public.as_json(only: [:html_text, :text, :time, :twitter_id])
    end

  end
end