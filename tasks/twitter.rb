namespace :twitter do

  desc "Corre el poller"
  task :realtime => :bootstrap do |task, args|
    client = Twitter::Streaming::Client.new do |config|
      config.consumer_key        = API::Config.twitter[:key]
      config.consumer_secret     = API::Config.twitter[:secret]
      config.access_token        = API::Config.twitter[:token]
      config.access_token_secret = API::Config.twitter[:access_token]
    end

    opts = {
      with: 'user'
    }

    publish_opts = {only: [:html_text, :text, :time, :twitter_id]}

    puts "Polling..."
    client.user(opts) do |object|
      puts object.class
      case object
        when Twitter::Tweet
          if !object.retweeted_status.nil?
            puts "retweet #{object.retweeted_status.id}"
            Tweet.retweet! object.retweeted_status.id
          else
            puts "tuit #{object.id}"
            next unless object.user.id == API::Config::twitter[:user]
            t = Tweet.from_archive(object.to_h)
            t.source = 'stream'
            t.save
            API::Stream.publish(:twitter, :tweet, t.as_json(publish_opts)) if t.original
          end


        when Twitter::Streaming::Event
          # no me importan los eventos de los demás
          next if object.source.id == API::Config.twitter[:user]
          puts object.name
          case object.name
            when :favorite then Tweet.fav! object.target_object.id
            when :unfavorite then Tweet.unfav! object.target_object.id
            when :follow then TwitterUser.follows_me object.source
            else puts "? #{object.name}"
          end
        when Twitter::Streaming::DeletedTweet
          Tweet.where({twitter_id: object.id}).delete
          API::Stream.publish(:twitter, :tweet, Tweet.last_public.as_json(publish_opts))
      end
    end
  end


  desc "Revisa followers"
  task :followers => :bootstrap do |task,args|

    known = TwitterUser.following_me.sort(twitter_id: 1).map {|u|
      [u.twitter_id, u]
    }.to_h
    puts "existentes: #{known.count}"

    current = []
    nuevos = []

    begin
      API::V1.twitter.followers(API::Config.twitter[:user], {
        skip_status: true,
        include_user_entities: false,
        count: 200,
      }).each do |u|
        # puts u.screen_name, u.created_at
        tid = u.id
        current << tid
        next if known.has_key? tid
        nuevos << TwitterUser.follow_me!(u)
      end
    rescue Twitter::Error::TooManyRequests => err
      puts "refresh en #{err.rate_limit.reset_in}"
      sleep err.rate_limit.reset_in
      retry
    else
      uf_ids = []
      fueron = (known.keys - current).map {|id|
        u = known[id]
        uf_ids << u.id
        "* [@#{u.handle}](https://twitter.com/intent/user?user_id=#{u.id}&screen_name=#{u.handle}) - #{u.name}"
      }


      if fueron.count > 0
        TwitterUser.unfollow_me! uf_ids

        text = <<MARKDOWN
# Habemus unfollowers

#{fueron.join("\n")}
MARKDOWN

        API::Mail.new("Unfollowers", text, :markdown).send_async
      end

    end
  end


  desc "Parse del archivo de twitter"
  task :ingesta, [:dir] => :bootstrap do |task, args|

    json = YAYSON.new(args[:dir])

    INDEX = json.parse("data/js/tweet_index.js")
    INDEX.each do |file|
      puts "#{file[:year]}-#{file[:month].to_s.rjust 2, '0'}"
      tuits = json.parse(file[:file_name])
      tuits.each do |tuit|
        next if tuit[:retweeted_status]
        t = Tweet.from_archive(tuit)
        t.save
      end
    end

  end


  desc "Descarga los tuits hasta ahora"
  task :poll, [:since] => :bootstrap do |task, args|

    $van = 0
    $last = Tweet.last_public.twitter_id

    def increment
      $van += 1
    end

    def imprime_total
      puts "Llevamos #{$van}"
    end

    def request max=nil
      opts = {
        count: 200,
        include_rts: false
      }
      opts[:max_id] = max unless max.nil?
      begin
        tuits = API::V1.twitter.user_timeline('unrob', opts)
        if tuits.empty?
          puts 'done!'
          exit
        end
      rescue Twitter::Error::TooManyRequests => error
        puts 'throttle'
        sleep error.rate_limit.reset_in + 1
      else
        tuits.each do |tuit|
          puts tuit.text
          if tuit.id == $last
            puts 'done!'
            exit
          end

          next unless tuit.retweeted_status.nil?
          increment
          t = Tweet.from_archive(tuit.to_h)
          t.source = 'stream'
          t.save
        end
        imprime_total
        request tuits.last.id - 1
      end
    end

    request

  end

end

require 'pp'
class YAYSON
  require 'json'

  @base = nil

  attr_reader :base

  def initialize base
    @base = File.expand_path base
  end

  def parse file
    str = File.read(full_path file)
    json = str.split(/\s*=\s*/, 2).last
    JSON.parse(json, symbolize_names: true)
  end

  private
  def full_path file
    "#{@base}/#{file}"
  end

end