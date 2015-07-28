module Api
  class Stream

    @@_host = nil

    class << self

      def configure host
        @@_host = host;
      end

      def publish channel, event, data
        base = "#{@@_host}/#{channel}/#{event}"
        HTTParty.post(base, body: data.to_json, headers: {'Content-type' => 'application/json'})
      end

    end

  end
end