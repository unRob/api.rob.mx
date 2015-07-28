module Event
  module Facebook

    def self.refresh_token
      auth = Koala::Facebook::OAuth.new Api::Config.facebook[:id], Api::Config.facebook[:secret]
      begin
        nuevo = auth.exchange_access_token(Api::Config.facebook[:access_token])
      rescue Exception => e
        puts e.message
      end
      API.set :facebook,  Koala::Facebook::API.new(nuevo)
      Api::Config.facebook[:access_token] = nuevo
      Api::Config.save
    end

    def self.process json, args
      data = JSON.parse(json, symbolize_names: true)

      data[:entry].each do |entry|
        begin
          result = API.facebook.get_object(*args)
        rescue Exception
          self.refresh_token
          result = API.facebook.get_object(*args)
        end

        result.each do |item|
          yield item['data'], Time.parse(item['start_time'])
        end
      end
    end #/process_inbound

  end
end