class AVMedia
  include Mongoid::Document

  field :service, type: Symbol
  field :public, type: Boolean, default: false
  field :time, type: Time, default: -> { Time.now }

  embeds_many :media, store_as: :media
end


class Media
  include Mongoid::Document

  field :url, type: String
  field :caption, type: String
  field :time, type: Time, default: -> { Time.now }
  field :type, type: Symbol, default: :image

  field :orientation, type: Symbol
  field :location

  field :sizes, type: Hash
  embeds_one :meta, as: :metadateable

  belongs_to :postcard

  index location: '2d'
  index({url: 1}, {unique: true, sparse: true})


  class << self

    def from_service service
      where({"meta.service" => service.to_s})
    end

  end
end

ActiveSupport::Inflector.inflections do |inflect|
  inflect.plural(/^(media)$/i, 'media')
  inflect.singular(/^(media)$/i, 'media')
end