class API::V1 < Sinatra::Base
  register Sinatra::Namespace

  namespace '/media' do

    get '/recent' do
      json Media.all.sort({time: -1}).limit(params[:limit] || 6)
    end

  end

end