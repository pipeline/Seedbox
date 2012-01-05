require 'data_mapper'

DataMapper.setup(:default, 'postgres://postgres@192.168.15.116/media')

DataMapper::Property::String.length(1024)

class Artist
  include DataMapper::Resource

  property :id,      Serial
  property :name,    String
  property :picture, String
end

class Album
  include DataMapper::Resource

  property :id,    Serial
  property :name,  String
  property :cover, String
end

class Song
  include DataMapper::Resource

  property :id,    Serial
  property :title, String
end

class Video
  include DataMapper::Resource

  property :id, Serial
  property :type, String
  property :cover, String
  property :trailer_url, String
  property :description, Text
  property :name, String
  property :rating, Float
end

class Episode
  include DataMapper::Resource

  property :id, Serial
  property :number, Integer
  property :season, Integer
end

class FileLocation
  include DataMapper::Resource

  property :id, Serial
  property :host, String
  property :path, Text
end

class User
  include DataMapper::Resource

  property :id, Serial
  property :email, String
  property :name, String
  property :hashed_password, String
end

class Artist
  has n, :albums
end

class Album
  belongs_to :artist
  has n, :songs
end

class FileLocation
  has n, :songs, :through => Resource
  has n, :episodes, :through => Resource
end

class Song
  belongs_to :album
  has n, :file_locations, :through => Resource
end

class Episode
  belongs_to :video
  has n, :file_locations, :through => Resource
end

DataMapper.finalize
DataMapper.auto_upgrade!
