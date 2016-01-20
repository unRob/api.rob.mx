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

    def from_instagram item
      exists = where("meta._id" => item.id)
      if exists.count > 0
        m = exists.first
        m.meta.likes = item.likes.count
        m.caption = item.caption.text if item.caption
        m.save
        return m
      end
      size = /(s\d+x\d+)/
      extra = /(([a-z]?\d+\.){3}\d+)/
      size_exp = %r!/#{size}!
      exp = %r!/(#{size}|#{extra})!

      data = {
        time: Time.at(item.created_time.to_i),
        url: item.link,
        type: item.type,
        meta: {
          id: item.id,
          likes: item.likes.count,
          service: 'instagram'
        }
      }

      data[:caption] = item.caption.text if item.caption

      if item.location
        data[:location] = {
          type: 'Point',
          coordinates: [
            item.location.longitude,
            item.location.latitude
          ]
        }
      end

      imgs = item.images
      data[:sizes] = {
        square: imgs.thumbnail.url.gsub(size_exp, ''),
        original: imgs.thumbnail.url.gsub(exp, '')
      }

      if item.videos
        data[:sizes][:video] = {
          low: item.videos.low_bandwidth.url,
          standard: item.videos.standard_resolution.url
        }
      end

      Media.create(data)
    end

    def from_service service
      where({"meta.service" => service.to_s})
    end

  end
end

ActiveSupport::Inflector.inflections do |inflect|
  inflect.plural(/^(media)$/i, 'media')
  inflect.singular(/^(media)$/i, 'media')
end