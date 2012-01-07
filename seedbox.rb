#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'erb'
require 'json'
require 'tvdb'
require './config.rb'
require './models.rb'

get '/' do
  @title = 'Dashboard'
  erb :dashboard
end

get '/report_files' do
  series = ['Battlestar Galactica', 'House', 'Cops', 'The IT Crowd', 'Burn Notice', 'Game of Thrones', 'The Office', 'Angel', 'Blackadder', 'Flashpoint', 'Dollhouse', 'Dr Who', 'Father Ted', 'Boston Legal', 'Black Books', 'Family Guy', 'Glee', 'Firefly', 'Invader Zim', 'Monty Python', 'Heroes', 'Spooks', 'The Wire', 'Dr. Horrible', 'Ultimate Force', 'Unauthorised History of NZ', 'Yes Minister', 'Yes, Prime Minister']

  #series = ['Glee', 'House', 'Black Books']

  series.each do |name|
    populate_series_details(name)
  end
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

