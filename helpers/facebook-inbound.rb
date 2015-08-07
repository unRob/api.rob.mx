module Event
  module Facebook

    def self.refresh_token
      auth = Koala::Facebook::OAuth.new Config.facebook[:id], Config.facebook[:secret]
      begin
        nuevo = auth.exchange_access_token(Config.facebook[:access_token])
      rescue Exception => e
        puts e.message
      end
      API.set :facebook,  Koala::Facebook::API.new(nuevo)
      Config.facebook[:access_token] = nuevo
      Config.save
    end

    def self.process json, args
      data = JSON.parse(json, symbolize_names: true)

      data[:entry].each do |entry|
        begin
          result = API::V1.facebook.get_object(*args)
        rescue Exception
          self.refresh_token
          result = API::V1.facebook.get_object(*args)
        end

        result.each do |item|
          yield item['data'], Time.parse(item['start_time'])
        end
      end
    end #/process_inbound

  end
end