module Api
  class Stream

    @@_url = nil
    @@_host = nil

    class << self

      def configure url, host=nil
        @@_url = url
        @@_host = host if host
      end

      def publish channel, event, data
        base = "#{@@_url}/#{channel}/#{event}"
        headers = {'Content-type' => 'application/json'}
        headers['Host'] = @@_host if @@_host

        HTTParty.post(base, body: data.to_json, headers: headers)
      end

    end

  end
end