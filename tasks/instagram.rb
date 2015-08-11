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
    max_id = nil
    loop do
      opts = {}
      opts[:max_id] = max_id if max_id
      res = client.user_recent_media(opts)
      max_id = res.pagination.next_max_id
      res.data.each do |pic|
      end

      break if max_id.nil?
    end
  end



end