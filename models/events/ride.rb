module Event
  class Ride
    include Mongoid::Document
    include Mongoid::Attributes::Dynamic
    store_in collection: 'event.rides'

    field :ingester, type: String, default: 'api'
    field :time, type: Time, default: -> {Time.now}

    field :activity, type: BSON::ObjectId
    field :distance, type: Float
    field :climb, type: Float
    field :duration, type: Float
    field :max_speed, type: Float
    field :avg_speed, type: Float
    field :reason, type: String
    field :places, type: Array

    has_many :humans, as: :humanizable


    def self.last_event_time query={}
      last = where(query).sort({time: -1}).first
      last = last ? last.time : 1.week.ago
      last.to_i
    end

  end
end