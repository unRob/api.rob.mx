module Event
  class Listen
    include Mongoid::Document
    include Mongoid::Attributes::Dynamic
    extend EventCollection::Top
    store_in collection: 'listens'

    field :ingester, type: String, default: 'api'
    field :time, type: Time, default: -> {Time.now}

    def self.last_event_time query={}
      where(query).sort({time: -1}).first.time
    end

  end
end