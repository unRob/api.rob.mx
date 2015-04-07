class API < Sinatra::Base
  register Sinatra::Namespace
  namespace '/music' do


    get '/search/:kind' do |kind|
      _to_id = [:artist, :album, :track, :genre]
      _query = _to_id+[:stub, :spotify_id]
      kind = kind.gsub(/s$/, '')

      raise Api::Error(400, 'Tipo de item inválido', validos: _to_id) if !_to_id.include? kind.to_sym

      data = params.reject {|k,v| !_query.include?(k.to_sym) }
      limit = params[:limit] && params[:limit].to_i || 10
      limit = [100, limit].min

      query = {}
      _to_id.each do |k|
        query[k] = BSON::ObjectId.from_string(params[k]) if params[k]
      end

      if params[:q]
        q = params[:q].to_s
        query['$or'] = [{name: /#{Regexp.escape q}/}, {stub: /#{Stub.new(q).to_s}/}]
      end
      data.delete 'q'
      data.delete 'p'

      skip = 0
      skip = params[:p].to_i.abs if params[:p]
      klass = kind.to_s.titleize.constantize
      query = query.merge(data)
      json({items: klass.where(query).skip(skip).limit(limit)})
    end


    listado = lambda do
      kind = request.path_info.split('/').last.gsub(/s$/, '')
      _to_id = [:artist, :album, :track, :genre]
      _query = _to_id+[:stub, :spotify_id]

      raise Api::Error.new(400, 'Tipo de item inválido', validos: _to_id) if !_to_id.include? kind.to_sym

      limit = params[:limit] && params[:limit].to_i || 10

      limit = [100, limit].min

      query = {}
      _to_id.each do |k|
        query[k] = BSON::ObjectId.from_string(params[k]) if params[k]
      end
      skip = 0
      skip = params[:p].to_i.abs if params[:p]
      klass = kind.to_s.titleize.constantize

      sort = {nombre: 1}
      if params[:sort]
        field, dir = params[:sort].split '|'
        if dir
          dir = dir == 'asc' ? 1 : -1
        else
          dir = 1
        end

        sort = {field => dir}
      end
      json({items: klass.where(query).sort(sort).skip(skip).limit(limit)})
    end

    get '/tracks', &listado
    get '/artist', &listado
    get '/albums', &listado
    get '/genres', &listado

    get '/stub/*' do
      comps = params[:splat].first.split('/')
      type = comps.shift
      stub = comps.join('/')

      klass = type.titleize
      raise Api::Error.new(400, 'Tipo desconocido') unless klass && ['artist', 'track', 'album', 'genre'].include?(type)
      item = klass.constantize.where(stub: stub).first

      raise Api::Error.new(404, "#{klass} inexistente") if item.nil?
      json item.as_json
    end


    get '/tracks/:track' do |id|
      item = Track.find(id)
      raise Api::Error.new(404) unless item
      json item.as_json
    end


    get '/albums/:album' do |id|
      item = Album.find(id)
      raise Api::Error.new(404) unless item
      json item.as_json deep: true
    end


    get '/artists/:artist' do |id|
      item = Artist.find(id)
      raise Api::Error.new(404) unless item
      json item.as_json deep: true
    end


    get '/genres/:genre' do |id|
      item = Genre.find(id)
      raise Api::Error.new(404) unless item
      json item.as_json
    end


  end
end