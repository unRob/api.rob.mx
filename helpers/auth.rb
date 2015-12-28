module Auth

  def self.registered app
    app.helpers AuthMethods
  end

  module AuthMethods
    def valid_credentials? token
      token == API::Config.me[:token]
    end
  end

end