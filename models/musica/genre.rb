class Genre
  include Mongoid::Document

  field :name, type: String
  field :stub, type: String

  has_many :tracks

  def as_json opts={}
    attrs = super opts

    attrs['_id'] = attrs['_id'].to_s
    attrs
  end

end