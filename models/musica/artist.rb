class Artist
  include Mongoid::Document

  field :name, type: String
  field :stub, type: String, default: -> {Stub.new(name).to_s}
  field :cover, type: String
  field :source, type: String
  field :spotify_id, type: String

  has_many :albums
  has_many :tracks

  def as_json opts={}
    deep = opts[:deep]
    opts.delete :deep
    attrs = super opts

    attrs['_id'] = attrs['_id'].to_s
    attrs[:tracks] = tracks.as_json if deep
    attrs[:albums] = albums.as_json if deep
    attrs
  end

end