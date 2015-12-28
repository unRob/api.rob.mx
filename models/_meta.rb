class Meta
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  embedded_in :metadatateable, polymorphic: true
  field :_id, default: nil, overwrite: true
end

ActiveSupport::Inflector.inflections do |inflect|
  inflect.plural(/^(meta)$/i, 'meta')
  inflect.singular(/^(meta)$/i, 'meta')
end