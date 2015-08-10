class AVMedia
  include Mongoid::Document

  field :service, type: Symbol
  field :public, type: Boolean, default: false
  field :time, type: Time, default: -> {Time.now}

  embeds_many :media, store_as: :media

end


class Photo

end