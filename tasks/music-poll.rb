namespace :music do

  desc "Descaga eventos sin albums and stuff"
  task :albumiza => :bootstrap do
    Event::Listen.where({artist: nil}).each do |evt|
      track = Track.find(evt.track)
      puts track.stub
      attrs = track.attributes
      evt.album = attrs['album_id']
      evt.genre = attrs['genre_id']
      evt.artist = attrs['artist_id']
      evt.save
    end
  end

  desc "Importa la librería de iTunes"
  task :itunes => :bootstrap do
    iml = File.expand_path('~/Music/iTunes/iTunes Music Library.xml')
    plist = Nokogiri::PList(open(iml))
    plist['Tracks'].each do |key, track|
      next if track['Kind'] =~ /(video|ringtone)/i || [nil, '', 'Audiobooks', 'Audiolibro', 'Voice Memo', 'Freestyle', 'Trova', 'Podcast'].include?(track['Genre']) || track['Artist'].nil?

      name = track['Name']
      artist_name = track['Artist']
      album_name = track['Album']


      artist = Artist.where({stub: Stub.new(artist_name)}).first
      if artist.nil?
        artist = Artist.create({
          name: artist_name,
          source: 'itunes'
        })
      end

      if album_name
        album = Album.where({stub: Stub.new(artist_name, album_name)}).first
        if album.nil?
          album = Album.create({
            name: album_name,
            source: 'itunes',
            artist: artist
          })
        end
      end

      genre = Genre.where({stub: Stub.new(track['Genre'])}).first

      track = {
        name: name,
        artist: artist,
        genre: genre,
        source: 'itunes'
      }
      track[:album] = album if album
      begin
        t = Track.create(track)
        puts t.stub
      rescue
        puts "--------------------"
        a = nil
        a = album.name if album
        puts Stub.new(artist.name, name, a)
        puts "--------------------"
      end
    end
  end


  desc "Importa los tracks de Spotify"
  task :facebook => :bootstrap do

    def mark url, time
      track = Spotify.track_for(url)
      Event::Listen.create({
        track: track.id,
        genre: track.genre.id,
        artist: track.artist.id,
        album: track.album.id,
        source: 'spotify',
        time: time
      })
    end

    def parse arr
      if arr.count == 0
        puts 'ended!'
        exit 0
      end

      puts '---> parsing page'
      arr.each do |item|
        data = item['data']
        time = Time.parse(item['start_time'])
        puts data['song']['title']
        begin
          mark data['song']['url'], time
        rescue Exception => e
          puts e.backtrace.reverse
          puts "#{e.class} ==> #{e.message}"
          puts data['song']
          exit
        end
      end

      puts "<--- Parsed hasta #{arr.next_page_params.to_json}"
      parse arr.next_page
    end

    parse API.facebook.get_object('me/music.listens', {limit: 100})
  end


  desc "Importa los tracks de api.spotify.com/me/player/recently-played"
  task :spotify => :bootstrap do
    config = API::Config.spotify
    client = SimpleSpotify::Client.new(config[:key], config[:secret])
    client.session = SimpleSpotify::Authorization.new({
      access_token: config[:token],
      refresh_token: config[:refresh],
      client: client
    })

    dataset = client.recently_played(50)
    keep_going = true
    max_processed = 130
    processed = 0
    lastRecorded = Event::Listen.last_event_time
    playTime = dataset.first.played_at

    if (playTime <= lastRecorded)
      puts 'ya tengo todo :/'
      exit
    end

    while keep_going
      dataset.each do |event|
        if (event.played_at <= lastRecorded || processed >= max_processed)

          puts event.played_at <= lastRecorded, processed >= max_processed
          puts
          keep_going = false
          break
        end

        track = Spotify.track_for(event.track.uri.split(":").last)
        evt = {
          track: track.id,
          album: track.album.id,
          genre: track.genre.id,
          artist: track.artist.id,
          source: 'spotify',
          time: event.played_at
        }
        puts "#{evt[:time]}: #{track.name} - #{track.artist.name}"

        Event::Listen.create(evt)
        processed += 1
      end

      puts 'asking for more...'
      dataset = dataset.more unless processed >= max_processed
      keep_going = !dataset.empty?
    end
  end


  desc "Importa los tracks de mi archivo de facebook"
  task :fb_crawl, [:path] => :bootstrap do |task, args|

    $mark_cache = {}
    def mark sp_song, time
      if (data = $mark_cache[sp_song.id]).nil?
        track = Spotify.track_for(sp_song)

        data = {
          track: track.id,
          genre: track.genre.id,
          artist: track.artist.id,
          album: track.album.id,
          source: 'spotify',
          source2: 'facebook',
        }
        $mark_cache[sp_song.id] = data
      end

      Event::Listen.create data.dup.merge({time: time})
    end

    dom = Nokogiri::HTML(open(File.expand_path(args[:path])))
    last = Event::Listen.last_event_time
    cache = {}

    dom.css('.contents div.meta').each do |fecha|
      time = Time.parse(fecha.text)
      next if last < time
      sib = fecha.next_sibling.text

      next unless sib =~ /^Rob Hidalgo listened to/
      clean = sib.slice(24..sib.length-13)
      last_by = clean.rindex(' by ')

      if last_by
        nombre = clean[0..last_by-1]
        artista = clean[last_by+4..clean.length]
        query = %["#{nombre.squish}" artist:#{artista}]
      else
        # rolas sin nombre
        nombre = clean.squish
        artista = '<varios artistas>'
        query = %["#{nombre}"]
      end

      sp_track = cache[query]
      if sp_track.nil?
        sp_track = SimpleSpotify.default_client.search(:track, query, market: 'mx').first
        if sp_track.nil?
          puts "!----FAIL---- #{sib}"
          next
        end
        cache[query] = sp_track
      end

      mark sp_track, time
      puts "#{nombre} /// #{artista}"

    end
  end


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