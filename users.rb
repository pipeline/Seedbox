#ActiveMerchant::Billing::Base.mode = :test
include ActiveMerchant::Billing

get '/user/login' do
  @title = 'Login'
  erb :login
end

post '/user/login' do
  @title = 'Login'
  user = User.first(:email => params[:email])
  if user.hashed_password == Digest::SHA1.hexdigest(params[:password])
    session[:user_id] = user.id
    redirect '/'
  else
    erb :login
  end
end

get '/user/logout' do
  session[:user_id] = nil
  redirect '/user/login'
end

get '/user/set_password' do
  @user = User.first(:hashed_password => params[:code])
  redirect '/user/login' and return if @user == nil
  session[:user_id] = @user.id
  @current_password = @user.hashed_password 
  erb :change_password
end

post '/users/change_password' do
  if (Digest::SHA1.hexdigest(params[:current_password]) == @user.hashed_password || params[:current_password] == @user.hashed_password) && params[:password] == params[:retype_password] then
    @user.hashed_password = Digest::SHA1.hexdigest(params[:password])
    @user.save
  end
  
  redirect '/settings'
end

post '/users/add' do
  password = generate_password
  email = params[:email]
  name = params[:name]
  User.create(
    :name => name,
    :email => email,
    :hashed_password => password,
    :admin => false
  )
  
  send_email(email, "Seedbox", "Hi #{name},<br>Welcome to the seedbox, <a href=\"http://#{SITE_DOMAIN}/user/set_password?code=#{password}\">Click here</a> to set your password.<br><br>--Me")
  
  redirect '/settings'
end

get '/users/credit_expired' do
  erb :credit_expired
end

get '/users/checkout' do
  setup_response = gateway.setup_purchase(1000,
    #:ip                => '127.0.0.1',
    :return_url        => "http://#{SITE_DOMAIN}/users/confirm_payment",
    :cancel_return_url => "http://#{SITE_DOMAIN}/"
  )

  pp setup_response.params

  redirect gateway.redirect_url_for(setup_response.token)
end

get '/users/confirm_payment' do
  puts "TOKEN NULL" and redirect '/' and return unless params[:token]
  
#  details_response = gateway.details_for(params[:token])
  
#  if !details_response.success?
#    puts "Details response was not successful:"
#    pp details
#    redirect '/'
#    return
#  end
    
  #@address = details_response.address
  
  purchase = gateway.purchase(1000,
    #:ip       => request.remote_ip,
    :payer_id => params[:PayerID],
    :token    => params[:token]
  )
  
  if !purchase.success?
    puts "PURCHASE WAS NOT SUCCESSFUL!"
    pp purchase
    redirect '/'
    return
  end
  
  if @user.credit_expires == nil || @user.credit_expires < Date.today
    @user.credit_expires = Date.today.next_month
  else
    @user.credit_expires = @user.credit_expires.next_month
  end
  @user.save

  redirect '/'
end

def generate_password(size=16)
  s = ""
  size.times { s << (i = Kernel.rand(62); i += ((i < 10) ? 48 : ((i < 36) ? 55 : 61 ))).chr }
  s
end

def send_email(address, subject, message)
  m = Mail.new do
    from "#{ADMIN_NAME} <#{ADMIN_EMAIL}>"
    to address
    subject subject
    html_part do |h|
      content_type 'text/html'
      body message
    end
  end

  m.deliver!
end

def gateway
  @gateway ||= PaypalExpressGateway.new(
    :login => PAYPAL_LOGIN,
    :password => PAYPAL_PASSWORD,
    :signature => PAYPAL_SIGNATURE
  )
end

