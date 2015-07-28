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

namespace :twitter do

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
        tuits = API.twitter.user_timeline('unrob', opts)
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