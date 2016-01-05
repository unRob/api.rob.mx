class API::V1 < Sinatra::Base
  register Sinatra::Namespace
  namespace '/stats/rides' do

    before do
      @since = nil
      @until = nil
      @query = nil
      @step = nil
      _periods = {y: :years, w: :weeks, m: :months, d: :days}

      if params
        @since = Time.at params[:since].to_i if params[:since]
        if params[:period]
          if params[:period] == 'all-time'
            @since = Time.at(0)
            @until = Time.now
          else
            count, period = params[:period].scan(/(\d+)(#{_periods.keys.join('|')})/).flatten
            raise Error.new(400, nil, valid_periods: _periods.keys) if count.nil? or period.nil?
            @until ||= Time.now
            @since = @until - count.to_i.send(_periods[period.to_sym])
          end
        else
          @until = Time.at params[:until].to_i if params[:until]
        end

        if params[:step]
          step = params[:step].to_sym
          raise Error.new(400, nil, valid_steps: _periods.keys) unless _periods.keys.include?(step)
          @step = _periods[step].to_s[0...-1].to_sym
        end

      end
    end


    get do
      query = {}

      @since = @since || 1.week.ago.beginning_of_day
      query[:started] = {'$gte' => @since} if @since
      query[:ended] = {'$lte' => @until} if @until

      rides = Ride.where(query).count
      aggregation = [
        {'$match' => query},
        {
          '$group' => {
            _id: nil,
            distance: {'$sum' => '$distance'},
            time: {'$sum' => '$moved_for'},
            elevation: {'$sum' => '$elevation'},
            speed: {'$avg' => '$avg_speed'}
          }
        }
      ]

      res = Ride.collection.aggregate(aggregation).first

      json({
        rides: rides,
        distance: res['distance'],
        elevation: res['elevation'],
        speed: res['speed'],
        time: res['time']
      })
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


  end
end