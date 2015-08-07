#encoding: utf-8
ENV['cwd'] = Dir.pwd
Rake::TaskManager.record_task_metadata = true

$dir = File.expand_path File.dirname(__FILE__)

task :env do
  require 'rubygems'
  require 'bundler'
  Bundler.require :script
  I18n.available_locales= [:es, :en]
  require "#{$dir}/config/boot.rb"
end

task :bootstrap => :env do
  require "#{$dir}/app.rb"
  API::V1.bootstrap
end

Dir["#{$dir}/tasks/**.rb"].each do |f|
  require f
end

task :default do
  Rake::application.options.show_tasks = :tasks
  Rake::application.options.show_task_pattern = //
  Rake::application.display_tasks_and_comments
end