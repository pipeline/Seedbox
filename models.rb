require 'data_mapper'

DataMapper.setup(:default, ENV['DATABASE_URL'] || 'postgres://seedbox:seedbox@127.0.0.1:5432/media')

DataMapper::Property::String.length(1024)
DataMapper::Model.raise_on_save_failure = true

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
  property :banner, String
  property :trailer_url, String
  property :description, Text
  property :name, String
  property :rating, Float
  property :poster, String
end

class Episode
  include DataMapper::Resource

  property :id, Serial
  property :number, Integer
  property :season, Integer
  property :name, String
  property :screenshot, String
  property :description, Text
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
  property :admin, Boolean
  property :credit_expires, Date
  
  has n, :feature_requests
  has n, :feature_request_votes
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

class ArchivedTorrent
  include DataMapper::Resource

  property :id, Serial
  property :piratebay_id, Integer
  property :name, String
  property :size, Integer
  property :popularity, Integer
  property :magnet, String
end

class FeatureRequest
  include DataMapper::Resource
  
  property :id, Serial
  property :completed, Boolean
  property :description, String
  
  belongs_to :user
  has n, :feature_request_votes
end

class FeatureRequestVote
  include DataMapper::Resource
  
  property :id, Serial
  
  belongs_to :feature_request
  belongs_to :user
end

DataMapper.finalize
DataMapper.auto_upgrade!
