module SSE

  module Helpers

    def register_stream channel
      settings.listeners[channel.to_sym] = []
    end

    def publish channel, data={}
      channel = channel.to_sym
      conns = settings.listeners[channel]
      settings.listeners.each {|k,v| puts "@#{k}: #{v.count} listeners"}
      return false if conns.empty?

      puts "Pushing to #{channel} (#{conns.count})"

      conns.each do |conn|
        conn << "event: #{channel}\n"
        conn << "data: #{data.to_json}\n\n"
      end

      true
    end

  end

  def self.registered(app)

    app.helpers Helpers

    app.set(:stream_mount, '/stream') unless app.respond_to? :stream_mount
    app.set(:listeners,  Hash.new {|h,k| h[k] = [] })

    app.get "#{app.stream_mount}/*" do
      channels = params[:splat].first.split(',')
      channels = channels.map(&:to_sym)

      content_type 'text/event-stream'

      stream(:keep_open) do |conn|
        puts "Aceptando conexión a @#{channels.join(', ')}"
        channels.each do |channel|
          settings.listeners[channel] << conn
        end

        conn.callback do
          puts 'disconnect'
          channels.each do |channel|
            settings.listeners[channel] << conn
          end
        end
      end
    end
  end

end