def gps_parse str, ref
  h,m,s = str.split(', ').map {|c|
    c.split('/').map(&:to_f).reduce(:/)
  }
  direction = (/[sw]/i =~ ref) ? -1 : 1;

  (h + m/60 + s/3600) * direction
end

class API::V1 < Sinatra::Base
  register Sinatra::Namespace
  namespace '/postal' do

    get '' do
      json Postcard.all.sort({time: -1}).limit(params[:limit] || 5)
    end

    get '/:id' do |id|
      json Postcard.find(id).as_json
    end


    post '' do
      halt 401 unless valid_credentials? request.env['HTTP_X_TOKEN']

      img = params[:file]
      data = params[:data]
      data[:meta] ||= {}

      original = img[:tempfile]
      image = MiniMagick::Image.open(original.path)
      exif = image.exif

      dt = exif['DateTime'].split(/\s/)
      dt[0].gsub!(':', '/')

      time = Time.parse(dt.join('T')+'Z')
      data[:time] = time
      coords = [
        gps_parse(exif['GPSLongitude'], exif['GPSLongitudeRef']),
        gps_parse(exif['GPSLatitude'], exif['GPSLatitudeRef'])
      ]
      data[:location] = { type: 'Point', coordinates: coords }

      data[:meta][:weather] = Weather.for_location(
        coords[0], coords[1], time
      )

      postal = Postcard.new(data)

      comps = ['postales', time.year, time.month]
      path = [API::Config.dropbox[:folder], *comps].join('/')

      settings.dropbox.put_file(path+"#{postal.id}.jpg", original)

      image.resize '1024x1024>'
      copias = File.open(image.path)
      settings.dropbox.put_file(path+"#{postal.id}-1024.jpg", copias)

      square = MiniMagick::Image.open(original.path)
      square.combine_options do |i|
        i.resize  '500x500^'
        i.gravity 'Center'
        i.extent  '500x500'
      end

      settings.dropbox.put_file(path+"#{postal.id}-500.jpg", square)

      url_base = [API::Config.dropbox[:base], *comps].join('/')

      postal.photo = Media.create({
        url: "/postal/#{postal.id}",
        type: "image",
        sizes: {
          square: "#{url_base}/#{postal.id}-500.jpg",
          original: "#{url_base}/#{postal.id}.jpg",
          :'1024' => "#{url_base}/#{postal.id}-1024.jpg",
        },
        orientation: case
          when image.width > image.height then :horizontal
          when image.width < image.height then :vertical
          else :square
        end,
        time: data[:time],
        location: data[:location],
        caption: params[:caption]
      })

      postal.save!

      status 201
      json postal.as_json
    end

  end # /namespace
end # /class