# encoding: utf-8

Encoding.default_external = 'utf-8'

$config_root = File.dirname(__FILE__)
ENV['app_root'] = File.dirname($config_root)

module Api
  class Config

    @@data = {}

    def self.path
      File.expand_path('./env', $config_root)
    end

    def self.setup
      lines = File.read(self.path).split("\n")

      lines = lines.reject {|l|
        l =~ /^[\#\n]/ || l == ''
      }

      lines.each do |line|
        e, k, v = line.split
        if !v
          key = e
          value = k
        else
          key = k
          value = @@data[key.to_sym] || {}
          value[e] = v
        end

        @@data[key.to_sym] = value
      end
    end

    def self.method_missing method, *args
      ms = method.to_s
      write = !((ms =~ /=$/).nil?)
      prop = ms.gsub('=', '').to_sym

      if @@data.keys.include? prop
        v = @@data[prop]

        if v.is_a? Hash
          if write
            @@data[prop][ENV['RACK_ENV']] = args.first
          else
            return v[ENV['RACK_ENV']]
          end
        else
          if write
            @@data[prop] = args.first
          else
            return v
          end
        end

      else
        raise NoMethodError, method
      end
    end

    def self.to_h
      @@data
    end

    def self.save
      File.open(self.path, 'w') do |f|
        @@data.each do |k,v|
          if v.is_a? Hash
            v.each do |e, val|
              f.puts "#{e} #{k} #{val}"
            end
          else
            f.puts "#{k} #{v}"
          end
        end
      end
    end

  end
end

if File.exists? Api::Config.path
  puts "Loading env"
  Api::Config.setup
end
