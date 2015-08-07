class Tweet
  include Mongoid::Document

  store_in collection: "twitter.tweet"

  field :twitter_id, type: Integer
  field :source, type: String, default: 'stream'
  field :text, type: String
  field :html_text, type: String, default: -> {
    str = text.dup
    plus = 0
    urls.each do |url|
      a = url.html(:display)
      range = url.range(plus)
      str[range] = a
      plus += a.length-(range.max-range.min)
    end
    str.gsub("\n", '<br />');
  }

  field :time, type: DateTime

  field :in_reply_to, type: Integer

  field :retweets, type: Integer, default: 0
  field :favs, type: Integer, default: 0
  field :geo, type: Hash

  field :hashtags, type: Array
  has_and_belongs_to_many :mentions, class_name: "TwitterUser"
  embeds_many :urls, class_name: 'TwitterURL', as: :twitter_url

  scope :original, -> do
    where(mention_ids: [])
  end

  def coordinates
    geo[:coordinates] rescue nil
  end

  def to_s
    text
  end

  def self.by_twitter_id id
    self.where({twitter_id: id})
  end

  def self.retweet! id
    self.by_twitter_id(id).inc(retweets: 1)
  end

  def self.fav! id
    self.by_twitter_id(id).inc(favs: 1)
  end

  def self.unfav! id
    self.by_twitter_id(id).inc(favs: -1)
  end


  def self.last_public
    self.original.order(time: -1).first
  end


  def self.from_archive t
    mentions = t[:entities][:user_mentions]
        .reject { |u| u[:id] == API::Config.twitter[:user] }
        .map { |u|
          TwitterUser.foc({
            twitter_id: u[:id],
            handle: u[:screen_name],
            name: u[:name],
          })
        }

    geo = nil
    if t[:geo]
      geo = t[:geo]
    elsif t[:place] && t[:place][:bounding_box] && t[:place][:bounding_box].count > 0
      bb = t[:place][:bounding_box][:coordinates][0]
      pairs = (bb + [bb.first]).each_cons(2)
      area = (1.0/2) * pairs.map {|(x0, y0), (x1,y1)|
        (x0*y1) - (x1*y0)
      }.inject(:+)

      centro = pairs.map do |(x0, y0), (x1,y1)|
        cross = (x0*y1 - x1*y0)
        [(x0+x1) * cross, (y0+y1) * cross]
      end.transpose.map {|cs| cs.inject(:+) / (6*area)}


      geo = {type: 'Point', coordinates: centro}
    end

    data = {
      source: 'ingesta',
      twitter_id: t[:id],
      text: t[:text],
      mentions: mentions,
      time: DateTime.parse(t[:created_at]),
      urls: t[:entities][:urls].map {|u| TwitterURL.from_entity(u)},
      hashtags: t[:entities][:hashtags].map {|ht| ht[:text].mb_chars.downcase.to_s}
    }

    data[:favs] = t[:favorite_count] if t[:favorite_count]
    data[:retweets] = t[:retweet_count] if t[:retweet_count]
    data[:in_reply_to] = t[:in_reply_to_status_id] if t[:in_reply_to_status_id]
    data[:geo] = geo if geo

    self.new(data)
  end

end