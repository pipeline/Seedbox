require './seedbox.rb'

set :environment, ENV['RACK_ENV'].to_sym
set :app_file,     'seedbox.rb'
disable :run

log = File.new("logs/sinatra.log", "a")
STDOUT.reopen(log)
STDERR.reopen(log)

run Sinatra::Application
