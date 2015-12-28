namespace :dropbox do

  desc 'prueba subir un archivo a drobpox'
  task :test, [:file] => :env do |task, args|
    client = DropboxClient.new(API::Config.dropbox[:token])
    path = File.expand_path(args[:file])
    file = File.read(path)
    name = path.split(File::SEPARATOR).last
    puts client.put_file(
      [API::Config.dropbox[:folder], name].join('/'),
      file
    )
    puts [API::Config.dropbox[:base], name].join('/');
  end

end