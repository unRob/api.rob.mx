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
  end


  module Periodical

    def project step, prop='$time'
      projection = {year: {'$year' => prop}}
      projection.merge(case step
        when :day then {month: {'$month' => prop}, day: {'$dayOfMonth' => prop}}
        when :week then {week: {'$week'=> prop}}
        when :month then {month: {'$month' => prop}}
        else {}
        end
      )
    end

    def period from, to, group=nil, q:{}, step: nil, props: nil
      group ||= {count: {'$sum' => 1}}
      props ||= [:time, :time]
      match = q || {}
      match[props.first] = {'$gte' => from}
      if props.first == props.last
        match[props.first]['$lte'] = to
      else
        match[props.last] = {'$lte' => to}
      end

      pipeline = []

      projection = self.project(step, "$#{props.first}")
      keys = projection.keys
      sort = keys.map {|k| ["_id.#{k}", 1]}.to_h

      extra = {}
      group.each do |k,v|
        next if k == :count
        extra[k] = v.values.first
      end

      pipeline << {'$match' => match}
      pipeline << {'$project' => {_id: projection}.merge(extra)}
      pipeline << {'$group' => {_id: '$_id'}.merge(group)}
      pipeline << {'$sort' => sort}

      collection.aggregate(pipeline).map {|v|
        id = v['_id']
        v['_id'] = case step
          when :day then Date.new(id['year'], id['month'], id['day'])
          when :week then Date.commercial(id['year'], id['week'])
          when :month then Date.new(id['year'], id['month'])
          when :year then Date.new(id['year'])
        end
        v
      }
    end

  end
end