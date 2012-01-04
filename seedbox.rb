#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'erb'

get '/' do
  @title = 'Dashboard'
  erb :dashboard
end

