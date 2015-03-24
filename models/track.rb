class Track
  include Mongoid::Document

  field :name, type: String
  field :stub, type: String
  field :source, type: String
  field :spotify_id, type: String

  belongs_to :album
  belongs_to :artist
  belongs_to :genre

  def as_json opts={}
    attrs = super opts

    attrs['_id'] = attrs['_id'].to_s
    attrs['album'] = album.as_json
    attrs['artist'] = artist.as_json
    attrs['genre'] = genre.as_json
    attrs.delete 'album_id'
    attrs.delete 'artist_id'
    attrs.delete 'genre_id'
    attrs
  end

end