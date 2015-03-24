# encoding: utf-8

require 'rubygems'
require 'bundler'

Bundler.require :http

I18n.available_locales= [:es, :en]

require './app.rb'

map '/' do
  run API
end
