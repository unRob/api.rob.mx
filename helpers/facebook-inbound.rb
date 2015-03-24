module Event
  module Facebook

    def self.refresh_token
      auth = Koala::Facebook::OAuth.new API::Config.facebook_id, API::Config.facebook_secret
      nuevo = auth.exchange_access_token(API::Config.access_token)
      API.set :facebook, nuevo
      API::Config.facebook_secret= nuevo
      API::Config.save
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