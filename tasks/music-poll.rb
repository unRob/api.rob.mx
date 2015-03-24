namespace :music do

  desc "Busca tracks sin album"
  task :albums_fill do
    Track.all.each do |track|
      album = track.attributes['album_id']

      if album.nil?
        # puts "Track #{track.name} - #{track.artist.name} no tiene album"
        next
      end

      if Album.find(album).nil?
        if track.spotify_id.nil?
          puts "#{track.id}: #{track.name} | no tiene spotify_id"
          next
        end

        sp_track = Spotify.track(track.spotify_id)
        sp_album = sp_track.album

        a = Album.where({spotify_id: sp_album.id}).first
        if a
          puts "#{track.id} si tiene album, mal etiquetado"
          track.album = a
          track.save
        else
          puts "#{track.id} not tiene album, creando"
          nuevo = {
            _id: album,
            name: sp_album.name,
            artist: track.artist,
            spotify_id: sp_album.id,
            source: 'spotify/poll'
          }
          cover = sp_album.images.first
          nuevo[:cover] = cover['url'] if cover
          Album.create!(nuevo)
        end
      end
    end
  end
  task :albums_fill => :bootstrap


  desc "Pone portadas a discos"
  task :cover => :bootstrap
  task :cover, [:type] do |task, args|
    kind = args[:type].to_sym
    unless [:album, :artist].include? kind
      puts "argumento inválido"
      exit 1
    end

    col = kind.to_s.titleize.constantize

    col.where({cover: nil, :spotify_id.exists => true}).each do |item|
      info = Spotify.send(kind, item.spotify_id)

      cover = info.images.first
      if cover
        puts "#{item.name} - #{cover['url']}"
        item.cover = cover['url']
        item.save
      end
    end
  end


end