# encoding: utf-8
module EventCollection
  module Top

    def top kind, qty, from=nil, to=nil, q: nil, period: nil

      query = []
      query << {'$group' => {_id: "$#{kind}", count: {'$sum' => 1}}}
      query << {'$sort' => {count: -1}}
      query << {'$limit' => qty}

      match = nil
      match = (q||{}) if (q || from || to)
      match[:time] ||= {} if from || to
      match[:time]['$gte'] = from if from
      match[:time]['$lte'] = to if to

      query.unshift({'$match' => match}) if match
      res = collection.aggregate(query)

      klass = "::#{kind.to_s.titleize}".constantize
      res.map! do |v|
        {
          count: v['count'],
          item: klass.find(v['_id'])
        }
      end

      res
    end


    def period from, to, q:{}, step: nil
      query = []
      match = q||{}
      match[:time] = {}
      match[:time]['$gte'] = from
      match[:time]['$lte'] = to

      projection = {year: {'$year' => '$time'}}
      projection.merge!(case step
        when :day then {month: {'$month' => '$time'}, day: {'$dayOfMonth' => '$time'}}
        when :week then {week: {'$week'=> '$time'}}
        when :month then {month: {'$month' => '$time'}}
        else {}
        end
      )

      keys = projection.keys
      id = keys.map {|k|
        [k, {"$#{k}" => '$_id'}]
      }.to_h

      sort = keys.map {|k| ["_id.#{k}", 1]}.to_h

      query << {'$match' => match}
      query << {'$project' => {_id: projection}}
      query << {'$group' => {_id: '$_id', count: {'$sum' => 1}}}
      query << {'$sort' => sort}

      res = collection.aggregate(query).map {|v|
        id = v['_id']
        v['_id'] = case step
          when :day then Date.new(id['year'], id['month'], id['day'])
          when :week then Date.commercial(id['year'], id['week'])
          when :month then Date.new(id['year'], id['month'])
          when :year then Date.new(id['year'])
        end
        v
      }
      res
    end

  end
end