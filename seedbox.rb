#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'erb'
require './models.rb'

get '/' do
  @title = 'Dashboard'
  erb :dashboard
end

