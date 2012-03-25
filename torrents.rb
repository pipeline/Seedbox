post '/torrents/search' do
  @title = "Search"
  @search_query = params[:search]
  @torrents = ArchivedTorrent.all(:conditions => ["name ILIKE ?", "%#{@search_query}%"], :order => [:popularity.desc])
  erb :torrent_search_results
end
  
post '/add_torrent' do
  add_torrent(params[:url])
end

get '/torrents/add_magnet' do
  add_torrent("magnet:?xt=urn:btih:#{params[:magnet]}&tr=udp%3A%2F%2Ftracker.openbittorrent.com%3A80&tr=udp%3A%2F%2Ftracker.publicbt.com%3A80&tr=udp%3A%2F%2Ftracker.ccc.de%3A80")
  redirect '/'
end

get '/torrents/current' do
  @current_torrents = get_current_torrents
  erb :current_torrents, {:layout => false}
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

def add_torrent(url)
  uri = URI("#{RUTORRENT_URL}php/addtorrent.php")
  puts "Adding torrent: #{url}"
  res = Net::HTTP.post_form(uri, :url => url)
  puts "GOT: "
  puts res.body
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

