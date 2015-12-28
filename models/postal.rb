class Postcard
  include Mongoid::Document

  field :time, type: Time
  field :to, type: Hash
  field :content, type: String
  field :html, type: String, default: -> {
    Maruku.new(content).to_html
  }

  field :location
  embeds_one :meta, as: :metadatateable
  has_one :media

  index location: '2d'
end