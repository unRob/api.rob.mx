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
  has_one :photo

  index location: '2d'
end

class Meta
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  embedded_in :metadatateable, polymorphic: true
end

ActiveSupport::Inflector.inflections do |inflect|
  inflect.plural(/^(meta)$/i, 'meta')
  inflect.singular(/^(meta)$/i, 'meta')
end