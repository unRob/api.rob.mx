class TwitterURL
  include Mongoid::Document

  field :_id, default: nil, overwrite: true
  embedded_in :twitter_url, polymorphic: true

  field :i, as: :indices, type: Array
  field :s, as: :short, type: String
  field :f, as: :full, type: String
  field :d, as: :display, type: String

  def range starting_at=0
    from, to = indices.map {|i| i+starting_at}
    (from...to)
  end

  def html kind=:full
    %{<a href="#{full}">#{send(kind)}</a>}
  end

  def self.from_entity data
    self.new({
      indices: data[:indices],
      short: data[:url],
      full: data[:expanded_url],
      display: data[:display_url]
    })
  end

end