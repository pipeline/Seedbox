#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'erb'
require 'json'
require 'mail'
require 'tvdb'
require 'activemerchant'
require 'net/http'
require 'digest/sha1'
require './models.rb'
require './torrents.rb'
require './users.rb'

enable :sessions

before do
  path = @env['PATH_INFO']
  if session[:user_id] == nil && path != '/user/login' && path != '/style.css' && path != '/user/set_password'
    redirect '/user/login'
  elsif session[:user_id] != nil
    @user = User.get(session[:user_id])
  end
  
  if @user != nil && (@user.credit_expires == nil || @user.credit_expires < Date.today) && @user.admin != true && path != '/users/credit_expired' && path != '/users/checkout' && path != '/users/confirm_payment' && path != '/user/set_password' && path != '/users/change_password' && path != '/user/logout'
    redirect '/users/credit_expired'
  end
end

helpers do
  def cycle
    %w{even odd}[@_cycle = ((@_cycle || -1) + 1) % 2]
  end
end

get '/' do
  @title = 'Dashboard'
  @current_torrents = get_current_torrents
  @feature_requests = FeatureRequest.all(:completed => false)
  erb :dashboard
end

get '/content' do
  @title = 'TV Series'
  @series = Video.all(:type => 'Series', :order => [:name.asc])
  erb :content
end

get '/report_files' do
  series = ['Battlestar Galactica', 'House', 'Cops', 'The IT Crowd', 'Burn Notice', 'Game of Thrones', 'The Office', 'Angel', 'Blackadder', 'Flashpoint', 'Dollhouse', 'Dr Who', 'Father Ted', 'Boston Legal', 'Black Books', 'Family Guy', 'Glee', 'Firefly', 'Invader Zim', 'Monty Python', 'Heroes', 'Spooks', 'The Wire', 'Dr. Horrible', 'Ultimate Force', 'Unauthorised History of NZ', 'Yes Minister', 'Yes, Prime Minister']

  #series = ['Glee', 'House', 'Black Books']

  series.each do |name|
    populate_series_details(name)
  end
end

post '/add_feature_request' do
  description = params[:description]
  
  FeatureRequest.create(
    :description => description,
    :completed => false,
    :user_id => 1
  )
  
  puts "Created feature request with description: #{description}"
  
  @feature_requests = FeatureRequest.all(:completed => false)
  erb :feature_requests, {:layout => false}
end

get '/settings' do
  @users = User.all
  erb :settings
end

get '/delete_feature_request' do
  id = params[:id]
  FeatureRequest.get(id).destroy
  redirect '/'
end

get '/complete_feature_request' do
  id = params[:id]
  feature = FeatureRequest.get(id)
  feature.completed = true
  feature.save
  redirect '/'
end

def populate_series_details(series_name)
  if Video.count(:name => series_name) != 0 then
    puts "SERIES ALREADY EXISTS: #{series_name}"
    return
  end

  $client ||= TVdb::Client.new(TVDB_API_KEY)
  results = $client.search(series_name)

  if results.count == 0 then
    puts "COULD NOT FIND SERIES: #{series_name}"
    return
  end

  result = nil
  results.each do |res|
    if res.seriesname.downcase[series_name.downcase] != nil then
      result = res
      break
    end
  end

  if result == nil then
    puts "COULD NOT FIND SERIES: #{series_name}"
    return
  end

  series = Video.create(
    :type => 'Series',
    :banner => result.banner,
    :description => result.overview,
    :name => result.seriesname,
    :rating => result.rating,
    :poster => result.poster
  )

  result.episodes.each do |ep|
    Episode.create(
      :video => series,
      :number => ep.episodenumber,
      :season => ep.seasonnumber,
      :name => ep.episodename,
      :screenshot => ep.filename,
      :description => ep.overview
    )
  end
end

get '/download_banners' do
  series = Video.all()
  series.each do |s|
    download_tvdb_file(s.banner)
  end
end

def download_tvdb_file(filename)
  public_path = File.dirname(__FILE__) + "/public/"
  puts "Downloading #{filename} to #{public_path}"

  Net::HTTP.start("thetvdb.com") { |http|
    resp = http.get("/banners/_cache/" + filename)
    open(public_path + filename, "wb") { |file|
      file.write(resp.body)
    }
  }
end

