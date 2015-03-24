class API < Sinatra::Base
  register Sinatra::Namespace
  namespace '/stats/listens' do

    before do
      @since = nil
      @until = nil
      @query = nil
      _to_id = [:artist, :album, :track, :genre]
      _query = _to_id+[:stub, :spotify_id]
      _periods = {y: :years, w: :weeks, m: :months, d: :days}

      if params
        @since = Time.at params[:since].to_i if params[:since]
        if params[:period]
          if params[:period] == 'all-time'
            @since = Time.at(0)
            @until = Time.now
          else
            count, period = params[:period].scan(/(\d+)(#{_periods.keys.join('|')})/).flatten
            raise ApiError.new(400, nil, valid_periods: _periods.keys) if count.nil? or period.nil?
            @until ||= Time.now
            @since = @until - count.to_i.send(_periods[period.to_sym])
          end
        else
          @until = Time.at params[:until].to_i if params[:until]
        end

        if params[:q]
          raise ApiError(400, 'El query debe ser un objeto') unless params[:q].is_a? Hash
          @query = params[:q].reject {|k,v| !_query.include?(k.to_sym) }
          puts params[:q]
          @query = @query.map {|k,v|
            if _to_id.include? k.to_sym
              v = BSON::ObjectId.from_string(v)
            else
              v = v.to_s
            end
            [k.to_sym, v]
          }.to_h

        end
      end
    end


    get do
      tracks = Event::Listen.top(:track, 5, @since, @until, q: @query).as_json
      # albums = Event::Listen.top(:album, 5, @since, @until, q: @query).as_json
      genres = Event::Listen.top(:genre, 5, @since, @until, q: @query).as_json
      artists = Event::Listen.top(:artist, 5, @since, @until, q: @query).as_json

      json({tracks: tracks, genres: genres, artists: artists})
    end


    get '/top/:kind' do |kind|
      kind = kind.gsub(/s$/, '').to_sym
      kinds = [:artist, :album, :genre, :track]

      raise ApiError.new(404, "No tengo stats para #{kind}", validos: kinds) unless kinds.include?(kind)

      limit = params[:limit] || 10
      limit = [100, limit.to_i].min

      @since ||= 1.week.ago.beginning_of_day if !!@until
      @until ||= @since+1.week if @since

      raise ApiError.new(400, 'Fechas inválidas') unless @since && @since < @until


      puts
      count_query = @query || {}
      count_query = count_query.merge({time: {'$gte'=>@since, '$lte'=> @until}})
      count = Event::Listen.where(count_query).count
      items = Event::Listen.top(kind, limit, @since, @until, q: @query)


      json({total: count, items: items, since: @since.localtime, until: @until.localtime})
    end

  end
end