class String
  def stub
    str = self
    if str == '-'
      str = 'dash'
    end
    I18n.transliterate(self).downcase.gsub(/[^a-z0-9~]/, ' ').squish.gsub(' ', '-')
  end
end