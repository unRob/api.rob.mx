class Stub


  def initialize *args
    @str = args.reject(&:nil?).map(&:stub).join('/')
  end

  def to_s
    @str
  end

end