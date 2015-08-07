namespace :mail do

  desc "Prueba el sistema de correos"
  task :test => :env do
    require_relative('../lib/api/mail')
    contacts = {
      api: {
        email: API::Config.api[:email],
        name: API::Config.api[:name],
        default_sender: true,
      },
      me: {
        email: API::Config.me[:email],
        name: API::Config.me[:name],
        default_recipient: true,
      }
    }
    API::Mail.configure(Mandrill::API.new(API::Config.mandrill), contacts)

    md = <<MD
# Mira, un salmón

* con markdown

> y así
MD
    API::Mail.new("Test", md, :markdown).send_async
  end

end