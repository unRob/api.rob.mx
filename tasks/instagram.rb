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

    loop do
      opts = {}
      opts[:max_id] = last if last
      res = client.user_recent_media(opts)
      last = res.pagination.next_max_id
      res.each do |item|
        m = Media.from_instagram(item)
        puts "#{m.type}: #{m.url}\n#{m.caption}\n\n"
      end

      break if last.nil?
    end
  end



end