class Image

  def metadata file
    info = EXIFR::JPEG.new(file)
    data = {
      time: info.date_time,
    }

    data[:location] = {
      type: "Point",
      coordinates: [info.gps.longitude, info.gps.latitude]
    } unless info.gps.nil?
    data
  end

end