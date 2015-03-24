namespace :facebook do

  desc "Suscribirse a notificaciones"
  task :subscribe, [:event, :endpoint] do |task, args|
    updates = Koala::Facebook::RealtimeUpdates.new({
      app_id: Config.facebook_id,
      secret: Config.facebook_secret
    })


    begin
      res = updates.subscribe "user", args[:event].split.join(','), args[:endpoint], Config.facebook_verify
    rescue Koala::Facebook::ClientError => e
      puts "ERROR"
      puts e.message
      puts e.response_body
    else
      puts res
    end
  end
  task :subscribe => :bootstrap

  desc "Desuscribirse a notificaciones"
  task :unsubscribe, [:event, :endpoint] do |task, args|
    updates = Koala::Facebook::RealtimeUpdates.new({
      app_id: Config.facebook_id,
      secret: Config.facebook_secret
    })

    begin
      res = updates.unsubscribe "user"
    rescue Koala::Facebook::ClientError => e
      puts "ERROR"
      puts e.message
      puts e.response_body
    else
      puts res
    end
  end
  task :unsubscribe => :bootstrap

end