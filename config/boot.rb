# encoding: utf-8
require 'yaml'
require 'pp'
Encoding.default_external = 'utf-8'

$config_root = File.dirname(__FILE__)
ENV['app_root'] = File.dirname($config_root)

module Api
  class Config

    @@data = {}

    def self.path
      File.expand_path('./env.yaml', $config_root)
    end

    def self.setup
      lines = File.read(self.path)
      YAML.load(lines).each do |scope, values|
        data = values
        if values.is_a? Array
          data = {}
          values.each do |val|
            env = val[:env].to_sym
            val.delete(:env)
            data[:_scoped] = true
            data[env] = val.map {|k,v| [k.to_sym, v]}.to_h
          end
        else
          data = values.map {|k,v| [k.to_sym, v]}.to_h if values.is_a?(Hash)
        end

        @@data[scope.to_sym] = data
      end
    end

    def self.method_missing meth, *args
      ms = meth.to_s

      op = nil
      if (ms.include? '[]')
        op = meth == :[] ? :get : :set
        prop = args.shift
        val = args.shift
        store = @@data[prop]
      else
        op = ms.include?('=') ? :set : :get;
        prop = ms.gsub('=', '').to_sym
        val = args.shift
        store = @@data[prop]
      end

      if op == :get
        # puts "get #{prop}"
        if store.is_a?(Hash) && store.has_key?(:_scoped)
          @@data[prop][ENV['RACK_ENV'].to_sym]
        else
          @@data[prop]
        end
      elsif op == :set
        # puts "set #{prop}"
        if store.is_a?(Hash) && store.has_key?(:_scoped)
          @@data[prop][ENV['RACK_ENV'].to_sym] = val
        else
          @@data[prop] = val
        end
      else
        raise NoMethodError, meth
      end
    end

    def self.to_h
      @@data
    end

    def self.save
      clean = {}
      @@data.each do |k,v|
        cfg = v
        if v.is_a?(Hash) && v.has_key?(:_scoped)
          cfg = []
          v.each do |ik, iv|
            next if ik == :_scoped
            cfg << {env: ik}.merge(iv)
          end
        end
        clean[k] = cfg
      end

      File.open(self.path, 'w') do |f|
        f << YAML.dump(clean)
      end
    end

  end
end

if File.exists? Api::Config.path
  puts "Loading env"
  Api::Config.setup
end