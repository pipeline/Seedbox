#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'erb'
require 'json'
require 'tvdb'
require 'net/http'
require './config.rb'
require './models.rb'

before do
  @user = User.get(1)
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

post '/add_torrent' do
  url = params[:url]
  uri = URI("#{RUTORRENT_URL}php/addtorrent.php")
  res = Net::HTTP.post_form(uri, :url => url)
end

get '/delete_torrent' do
  hash = params[:hash]
  uri = URI("#{RUTORRENT_URL}")
  http = Net::HTTP.new(uri.host, uri.port)
  post = Net::HTTP::Post.new("#{uri.path}plugins/httprpc/action.php")
  post.basic_auth RUTORRENT_USERNAME, RUTORRENT_PASSWORD
  post.body = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><methodCall><methodName>system.multicall</methodName><params><param><value><array><data><value><struct><member><name>methodName</name><value><string>d.set_custom5</string></value></member><member><name>params</name><value><array><data><value><string>#{hash}</string></value><value><string>1</string></value></data></array></value></member></struct></value><value><struct><member><name>methodName</name><value><string>d.delete_tied</string></value></member><member><name>params</name><value><array><data><value><string>#{hash}</string></value></data></array></value></member></struct></value><value><struct><member><name>methodName</name><value><string>d.erase</string></value></member><member><name>params</name><value><array><data><value><string>#{hash}</string></value></data></array></value></member></struct></value></data></array></value></param></params></methodCall>"
  http.request(post)
  redirect '/'
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

def get_current_torrents
  uri = URI("#{RUTORRENT_URL}plugins/httprpc/action.php")
  res = Net::HTTP.post_form(uri, :mode => 'list')

  torrents = []
  json = JSON.parse(res.body)['t']
  pp json

  return {} if json == []
  json.each_pair {|hash, values|
    torrents << {
      :name => values[4],
      :percent => ((values[8].to_f / values[5].to_f) * 100.0).to_i,
      :hash => hash,
      :done => (values[8] == values[5]),
      :download_url => "#{FTP_URL}#{values[25].gsub(FTP_HOME, "")}"
    }
  }

  return torrents
end

