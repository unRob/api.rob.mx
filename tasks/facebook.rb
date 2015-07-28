namespace :facebook do

  desc "Suscribirse a notificaciones"
  task :subscribe, [:event, :endpoint] do |task, args|

    updates = Koala::Facebook::RealtimeUpdates.new({
      app_id: Api::Config.facebook[:id],
      secret: Api::Config.facebook[:secret]
    })


    begin
      res = updates.subscribe "user", args[:event].split.join(','), args[:endpoint], Api::Config.facebook[:verify]
    rescue Koala::Facebook::ClientError => e
      puts "ERROR"
      puts e.message
      puts e.response_body
    else
      puts res
    end
  end
  task :subscribe => :bootstrap

  task :list => :bootstrap do
    updates = Koala::Facebook::RealtimeUpdates.new({
      app_id: Api::Config.facebook[:id],
      secret: Api::Config.facebook[:secret]
    })
    puts updates.list_subscriptions
  end

  desc "Desuscribirse a notificaciones"
  task :unsubscribe, [:event, :endpoint] do |task, args|
    updates = Koala::Facebook::RealtimeUpdates.new({
      app_id: Api::Config.facebook[:id],
      secret: Api::Config.facebook[:secret]
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