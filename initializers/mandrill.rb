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