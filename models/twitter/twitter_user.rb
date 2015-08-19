class TwitterUser
  include Mongoid::Document

  store_in collection: "twitter.user"

  has_and_belongs_to_many :tweets, inverse_of: nil

  field :handle, type: String
  field :name, type: String
  field :aka, type: Array, default: []
  field :twitter_id, type: Integer
  field :follows_me, type: Boolean, default: false
  field :unfollowed_me, type: Time
  field :followed_me, type: Time


  def self.follow_me! user
    self.foc({
      handle: user.screen_name,
      name: user.name,
      twitter_id: user.id,
      follows_me: true,
      followed_me: user.created_at
    })
  end


  def self.unfollow_me! users
    where(:_id.in => users).update_all({
      follows_me: false,
      unfollowed_me: Time.now
    })
  end


  def self.following_me
    where({follows_me: true})
  end


  def self.foc data
    existing = self.where({twitter_id: data[:twitter_id]}).first
    if existing
      if existing.handle != data[:handle]
        old_handle = existing.handle.dup
        existing.handle = data[:handle]
        existing.aka << old_handle
      end

      existing.name = data[:name] unless existing.name == data[:name]

      if data[:follows_me] == true
        existing.followed_me = data[:followed_me]
        existing.follows_me = true
      end
      existing.save
      existing
    else
      self.create(data)
    end
  end

end