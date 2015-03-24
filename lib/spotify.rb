class Spotify

  def self.album(id)
    RSpotify::Album.find(id)
  end

  def self.track id
    RSpotify::Track.find(id)
  end

  def self.artist id
    RSpotify::Artist.find(id)
  end


  def self.query_genre name=nil
    name = name.squish
    name = 'indie' if name.nil? or name == ''

    query = {stub: name.stub}
    genre = Genre.where(query).first
    if genre.nil?
      genre = Genre.create({name: name}.merge(stub))
    end
  end


  def self.query_album album, artist
    stub = Stub.new(artist.name, album.name)
    a = Album.or({spotify_id: album.id}, {stub: stub}).first

    if a
      a.spotify_id = album.id unless a.spotify_id
      a.cover = album.images.first['url'] unless a.cover
    else
      a = Album.new({
        artist: artist,
        name: album.name,
        spotify_id: album.id,
        stub: stub,
        source: 'spotify'
      })
    end

    a.save! if a.changed?
    a
  end


  def self.query_artist artist
    stub = artist.name.stub
    a = Artist.or({spotify_id: artist.id}, {stub: stub}).first

    if a
      a.spotify_id = a.id
      a.cover = artist.images.first['url'] unless a.cover
    else
      a = Artist.new({
        name: artist.name,
        stub: stub,
        spotify_id: artist.id,
        source: 'spotify'
      })
    end

    a.save!
    a
  end


  def self.query_track url
    sp_song = RSpotify::Track.find(url)
    sp_album = sp_song.album
    sp_artist = sp_song.artists.first

    genres = sp_artist.genres.concat(sp_album.genres)+['indie']

    artist = self.query_artist(sp_artist)
    album = self.query_album sp_album, artist
    genre = self.query_genre genres.first

    stub = Stub.new artist.name, sp_song.name, album.name
    track = Track.where({stub: stub}).first

    if track
      track.spotify_id = sp_song.id
    else
      track = Track.new({
        name: sp_song.name,
        artist: artist,
        genre: genre,
        album: album,
        stub: stub,
        spotify_id: sp_song.id,
        source: 'spotify'
      })
    end

    track.save!

    return track
  end


  def self.track_for url
    url = url.split('/').last
    track = Track.where(spotify_id: url).first
    return track if track

    self.query_track(url)
  end

end