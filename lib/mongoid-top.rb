# encoding: utf-8
module EventCollection
  module Top

    def top kind, qty, from=nil, to=nil, q: nil

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
end