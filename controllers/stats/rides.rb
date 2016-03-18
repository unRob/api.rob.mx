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
      if rides > 0
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
      else
        res = {
          'distance' => 0,
          'elevation' => 0,
          'speed' => 0,
          'time' => 0
        }
      end

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
      count_query[:started] = {'$gte' => @since, '$lte'=>@until}

      result[:count] = Ride.where(count_query).count
      result[:since] = @since if @since
      result[:until] = @until if @until

      if @step
        group = {
          count: {'$sum' => 1},
          distance: {'$sum' => '$distance'},
          moved_for: {'$sum' => '$moved_for'},
          elevation: {'$sum' => '$elevation'},
          avg_speed: {'$avg' => '$avg_speed'}
        }
        items = Ride.period(@since, @until, group,q: @query, step: @step, props: [:started, :ended])

        curr = @since
        curr = items.first['_id'].to_date if !items.empty? && @step == :week

        range = {}
        while curr <= @until do
          date = curr.to_date
          date = Date.new(date.year, date.month) if @step == :month
          date = Date.new(date.year) if @step == :year
          range[date] = {rides: 0, time: 0, speed: 0, distance: 0, elevation: 0}
          curr += 1.send(@step)
        end

        items = items.map {|i|
          id = i['_id']
          i.delete('_id')
          val = i
          val[:time] = val['moved_for']
          val[:speed] = val['avg_speed']
          val.delete 'moved_for'
          val.delete 'avg_speed'
          [id, val]
        }.to_h

        result[:items] = range.map {|k, v|
          v = items[k] || v
          k = case @step
            when :week then "#{k.year}-S#{k.cweek.to_s.rjust(2, '0')}"
            when :month then "#{k.year}-#{k.month.to_s.rjust(2, '0')}"
            when :year then k.year
            else k
          end
          {_id: k.to_s, stats: v}
        }

      end
      json result
    end


  end
end