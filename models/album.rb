class Album
  include Mongoid::Document

  field :name, type: String
  field :stub, type: String, default: -> {Stub.new(artist.name, name)}
  field :spotify_id, type: String
  field :source, type: String

  field :cover, type: String
  belongs_to :artist
  has_and_belongs_to_many :tracks

  def as_json opts={}
    attrs = super opts
    attrs['_id'] = attrs['_id'].to_s
    attrs['artist'] = artist.as_json
    attrs.delete 'artist_id'
    attrs
  end

end