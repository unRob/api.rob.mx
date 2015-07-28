class TwitterUser
  include Mongoid::Document

  store_in collection: "twitter.user"

  has_and_belongs_to_many :tweets, inverse_of: nil

  field :handle, type: String
  field :name, type: String
  field :aka, type: Array, default: []
  field :twitter_id, type: Integer


  def self.foc data
    existing = self.where({twitter_id: data[:twitter_id]}).first
    if existing
      if existing.handle != data[:name]
        old_handle = existing.handle.dup
        existing.handle = data[:handle]
        existing.aka << old_handle
      end
      existing.name = data[:name] unless existing.name == data[:name]
      existing
    else
      self.create(data)
    end
  end

end