class Ride
  include Mongoid::Document

  field :strava_id, type: String
  field :name, type: String

  field :started, type: Time
  field :ended, type: Time
  field :moved_for, type: Float

  field :elevation, type: Float
  field :distance, type: Float
  field :track, type: Hash

  field :max_speed, type: Float
  field :avg_speed, type: Float

  field :commute, type: Boolean

end