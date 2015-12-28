namespace :instagram do

  desc "Suscribirse a notificaciones"
  task :subscribe, [:endpoint] => :bootstrap do |task, args|
    ep = args[:endpoint]

    puts Instagram.create_subscription 'user', ep, 'media'
  end


  desc "Baja fotos hasta ahora"
  task :fetch => :bootstrap do

    client = Instagram.client(access_token: API::Config.instagram[:token])
    # https://api.instagram.com/v1/users/self/media/recent?access_token=
    last = Media.from_service(:instagram).sort({time: 1}).first.meta[:id] rescue nil

    size = /(s\d+x\d+)/
    extra = /(([a-z]?\d+\.){3}\d+)/
    size_exp = %r!/#{size}!
    exp = %r!/(#{size}|#{extra})!

    loop do
      opts = {}
      opts[:max_id] = last if last
      res = client.user_recent_media(opts)
      last = res.pagination.next_max_id
      res.each do |pic|

        data = {
          time: Time.at(pic.created_time.to_i),
          url: pic.link,
          type: pic.type,
          meta: {
            id: pic.id,
            likes: pic.likes.count,
            service: 'instagram'
          }
        }

        data[:caption] = pic.caption.text if pic.caption

        if pic.location
          data[:location] = {
            type: 'Point',
            coordinates: [
              pic.location.longitude,
              pic.location.latitude
            ]
          }
        end

        imgs = pic.images
        data[:sizes] = {
          square: imgs.thumbnail.url.gsub(size_exp, ''),
          original: imgs.thumbnail.url.gsub(exp, '')
        }

        if pic.videos
          data[:sizes][:video] = {
            low: pic.videos.low_bandwidth.url,
            standard: pic.videos.standard_resolution.url
          }
        end

        m = Media.create(data)
        puts "#{m.type}: #{m.url}\n#{m.caption}\n\n"
      end

      break if last.nil?
    end
  end



end