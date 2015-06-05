# encoding: utf-8

require 'rubygems'
require 'bundler'

Bundler.require :http

I18n.available_locales= [:es, :en]

require './app.rb'

run API

# require 'sinatra'
# require 'time'

# get '/' do
#   <<-STR
#     <div id="messages"></div>

#     <script>
#       var source = new EventSource('/stream');
#       var messages = document.getElementById('messages');

#       source.onopen = function(){
#         var msg = document.createElement('p')
#         msg.innerText = 'open'
#         messages.appendChild(msg)
#       };

#       source.onerror = function(e) {
#         var msg = document.createElement('p')
#         msg.innerText = 'error'
#         messages.appendChild(msg)
#       };

#       source.onmessage = function(evt) {
#          var msg = document.createElement('p')
#         msg.innerText = evt.data;
#         messages.appendChild(msg)
#       };
#     </script>
# STR
# end

# set :listeners, []

# get '/stream', provides: 'text/event-stream' do
#   response.headers['X-Accel-Buffering'] = 'off'
#   stream(:keep_open) do |conn|
#     puts 'conn'

#     settings.listeners << conn
#     puts "count: #{settings.listeners.count}"

#     conn.callback do
#       puts 'disconnect'
#       puts "count: #{settings.listeners.count}"
#       settings.listeners.delete(conn)
#     end
#   end
# end

# get '/publish' do
#   puts "count: #{settings.listeners.count}"
#   settings.listeners.each do |conn|
#     conn << "data: #{Time.now}\n\n"
#   end
#   'ok'
# end

# run Sinatra::Application