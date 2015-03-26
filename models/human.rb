class Human
  include Mongoid::Document

  field :name, type: String
  field :last_name, type: String
  field :nickname, type: String, default: -> {name}
  field :gender, type: String

  field :met, type: Time
  field :context, type: String, default: 'personal'

  belongs_to :humanizable, polymorphic: true

end