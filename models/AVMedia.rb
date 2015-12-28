class AVMedia
  include Mongoid::Document

  field :service, type: Symbol
  field :public, type: Boolean, default: false
  field :time, type: Time, default: -> { Time.now }

  embeds_many :media, store_as: :media

end


class Photo
  include Mongoid::Document

  field :url, type: String
  field :caption, type: String
  field :time, type: Time, default: -> { Time.now }

  field :orientation, type: Symbol
  field :location

  field :sizes, type: Hash

  belongs_to :postcard

  index location: '2d'
  index({url: 1}, {unique: true, sparse: true})
end