module Event
  module Facebook

    def self.refresh_token
      auth = Koala::Facebook::OAuth.new Api::Config.facebook_id, Api::Config.facebook_secret
      nuevo = auth.exchange_access_token(Api::Config.access_token)
      API.set :facebook, nuevo
      Api::Config.facebook_secret= nuevo
      Api::Config.save
    end

    def self.process json, args
      data = JSON.parse(json, symbolize_names: true)

      data[:entry].each do |entry|
        begin
          data = API.facebook.get_object(*args)
        rescue Exception
          self.refresh_token
          data = API.facebook.get_object(*args)
        end

        data.each do |item|
          yield item['data'], Time.parse(item['start_time'])
        end
      end
    end #/process_inbound

  end
end