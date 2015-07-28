class API < Sinatra::Base
  register Sinatra::Namespace
  namespace '/stats/listens' do

    before do
      pass if request.path_info.start_with? '/stats/listens/last'
      @since = nil
      @until = nil
      @query = nil
      @step = nil
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
            raise Api::Error.new(400, nil, valid_periods: _periods.keys) if count.nil? or period.nil?
            @until ||= Time.now
            @since = @until - count.to_i.send(_periods[period.to_sym])
          end
        else
          @until = Time.at params[:until].to_i if params[:until]
        end

        if params[:step]
          step = params[:step].to_sym
          raise Api::Error.new(400, nil, valid_steps: _periods.keys) unless _periods.keys.include?(step)
          @step = _periods[step].to_s[0...-1].to_sym
        end

        if params[:q]
          raise Api::Error(400, 'El query debe ser un objeto') unless params[:q].is_a? Hash
          @query = params[:q].reject {|k,v| !_query.include?(k.to_sym) }
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
      query = {time: {}}

      @since = @since || 1.week.ago.beginning_of_day
      query[:time]['$gte'] = @since if @since
      query[:time]['$lte'] = @until if @until

      plays = Event::Listen.where(query).count
      tracks = Event::Listen.top(:track, 5, @since, @until, q: @query).as_json
      albums = Event::Listen.top(:album, 5, @since, @until, q: @query).as_json
      genres = Event::Listen.top(:genre, 5, @since, @until, q: @query).as_json
      artists = Event::Listen.top(:artist, 5, @since, @until, q: @query).as_json

      json({tracks: tracks, genres: genres, artists: artists, albums: albums, plays: plays})
    end


    get '/last/:kind' do |kind|
      kinds = %w{artist album track genre}
      raise Api::Error.new(404, "No tengo eventos para #{kind}", validos: kinds) unless kinds.include?(kind)

      event = Event::Listen.only(kind.to_sym, :time, :source, :id).sort(time: -1).first
      item = kind.capitalize.constantize.find(event.send(kind.to_sym))

      data = {time: event.time, source: event.source, id: event.id.to_s}
      data[kind] = item.as_json;
      json(data)
    end


    get '/period' do
      result = {}
      count_query = {}
      count_query[:time] = {'$gte' => @since, '$lte'=>@until}

      result[:count] = Event::Listen.where(@query.merge count_query).count
      result[:since] = @since if @since
      result[:until] = @until if @until

      if @step
        items = Event::Listen.period(@since, @until, q: @query, step: @step)

        curr = @since
        curr = items.first['_id'].to_date if !items.empty? && @step == :week

        range = {}
        while curr <= @until do
          date = curr.to_date
          date = Date.new(date.year, date.month) if @step == :month
          date = Date.new(date.year) if @step == :year
          range[date] = 0
          curr += 1.send(@step)
        end

        items = items.map {|i| [i['_id'], i['count']]}.to_h

        result[:items] = range.map {|k, v|
          v = items[k] || v
          k = case @step
            when :week then "#{k.year}-S#{k.cweek}"
            when :month then "#{k.year}-#{k.month}"
            when :year then k.year
            else k
          end
          {_id: k.to_s, count: v}
        }

      end
      json result
    end


    get '/top/:kind' do |kind|
      kind = kind.gsub(/s$/, '').to_sym
      kinds = [:artist, :album, :genre, :track]

      raise Api::Error.new(404, "No tengo stats para #{kind}", validos: kinds) unless kinds.include?(kind)

      limit = params[:limit] || 10
      limit = [100, limit.to_i].min

      @since ||= 1.week.ago.beginning_of_day unless @until
      @until ||= @since+1.week if @since

      raise Api::Error.new(400, 'Fechas inválidas') if @since && @until && @since > @until

      count_query = @query || {}

      if @since
        count_query[:time] = {'$gte' => @since}
      end

      if @until
        count_query[:time] ||= {}
        count_query[:time]['$lte'] = @until
      end
      count = Event::Listen.where(count_query).count
      items = Event::Listen.top(kind, limit, @since, @until, q: @query)

      results = {total: count, items: items}
      results[:since] = @since.localtime if @since
      results[:until] = @until.localtime if @until
      json results
    end

  end
end