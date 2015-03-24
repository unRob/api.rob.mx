class ApiError < StandardError

  @@codes = {
    400 => 'Bad request',
    401 => 'Unauthorized',
    402 => 'Payment Required',
    403 => 'Forbidden',
    404 => 'Not found',
    405 => 'Method not allowed',
    406 => 'Not acceptable',

    409 => 'Conflict',
    418 => 'I\'m a teapot'
  }

  attr_reader :http_code, :code, :message, :data

  def initialize code, message=nil, extra={}
    @http_code = code
    @message = message || @@codes[code]
    @data = extra || {}

    super code
  end

  def to_json
    {
      http_code: http_code,
      error: message,
    }.merge(data)
  end

end