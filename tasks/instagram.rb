namespace :instagram do

  desc "Suscribirse a notificaciones"
  task :subscribe, [:endpoint] => :bootstrap do |task, args|
    ep = args[:endpoint]

    puts Instagram.create_subscription 'user', ep, 'media'
  end

end