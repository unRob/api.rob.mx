class Weather

  def self.for_location lng, lat, time=nil
    time ||= Time.now
    time_i = (time.to_i/3600).round * 3600

    params = {
      units: :ca,
      exclude: 'daily,flags,minutely,hourly',
      lang: 'es'
    }

    url = "https://api.forecast.io/forecast/04996db896a3d5ec1116a0550432ca50/"
    url += [lat,lng,time_i].join(',')
    url += "?"
    url += params.map {|k,v| "#{k}=#{v}" }.join('&')

    res = JSON.parse(open(url).read, symbolize_names: true)[:currently]

    {
      temp: res[:temperature],
      pressure: res[:pressure],
      humidity: res[:humidity],
      wind: res[:windSpeed]
    }
  end

end