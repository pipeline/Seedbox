require './seedbox.rb'

set :environment, ENV['RACK_ENV'].to_sym
set :app_file,     'seedbox.rb'
disable :run

run Sinatra::Application
