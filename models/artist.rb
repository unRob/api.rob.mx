class Artist
  include Mongoid::Document

  field :name, type: String
  field :stub, type: String
  field :cover, type: String
  field :source, type: String
  field :spotify_id, type: String

  has_many :albums
  has_many :tracks

  def as_json opts={}
    attrs = super opts

    attrs['_id'] = attrs['_id'].to_s
    attrs
  end

end