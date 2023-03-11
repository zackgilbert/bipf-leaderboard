require 'dotenv'
require 'rubygems'
require 'sinatra'
require 'sinatra/activerecord'
require './config/environment'
require 'oauth'
require 'json'
require 'twitter'
require 'linkedin'
require 'httparty'

Dotenv.load()

#SERVER_HOST = '0.0.0.0'
#SERVER_PORT = '3000'
BASE_URL    = ENV['BASE_URL']

TWITTER_KEY            = ENV['TWITTER_KEY']
TWITTER_SECRET         = ENV['TWITTER_SECRET']
TWITTER_CALLBACK       = "#{BASE_URL}/auth/twitter/callback"

LINKEDIN_KEY           = ENV['LINKEDIN_KEY']
LINKEDIN_SECRET        = ENV['LINKEDIN_SECRET']
LINKEDIN_CALLBACK      = "#{BASE_URL}/auth/linkedin/callback"
LINKEDIN_SCOPE         = 'r_liteprofile' #'r_basicprofile+r_member_social'

PROGRAM_START_DATE = '2023-03-08'
PROGRAM_END_DATE = '2023-04-14'
PROGRAM_WEEK_OFFSET = 9

# Sinatra settings
enable :sessions

#set :bind, SERVER_HOST
#set :port, SERVER_PORT

#set :static, false
#set :run, true

helpers do

  def current_week
    Date.today.cweek - PROGRAM_WEEK_OFFSET
  end

  def selected_week
    if params[:week].present? && params[:week].to_i > 0
      params[:week].to_i
    else
      current_week
    end
  end

  def weeks
    from = Date.parse(PROGRAM_START_DATE)
    to = Date.parse(PROGRAM_END_DATE)
    w = {}
    (from..to).group_by(&:cweek).map do |group|
      start_of_week = group.last.first.beginning_of_week
      w[group.first - PROGRAM_WEEK_OFFSET] = { 
        start: (start_of_week > from) ? start_of_week : from,
        end: group.last.last.end_of_week
      }
    end
    w
  end

  def login?
    !session[:atoken].nil?
  end

  def profile
    linkedin_client.profile unless session[:atoken].nil?
  end

  def connections
    linkedin_client.connections unless session[:atoken].nil?
  end

  private
  def linkedin_client
    client = LinkedIn::Client.new(settings.api, settings.secret)
    client.authorize_from_access(session[:atoken])
    client
  end

end

get '/' do
  erb :twitter
end

# Twitter
get '/twitter' do
  redirect '/'
end

get '/auth/twitter' do
  oauth = OAuth::Consumer.new(
    TWITTER_KEY,
    TWITTER_SECRET,  
    :site => 'https://api.twitter.com',
    :scheme => :header,
    :http_method => :post,
    :request_token_path => "/oauth/request_token",
    :access_token_path => "/oauth/access_token",
    :authorize_path => "/oauth/authorize"
  )
  request_token            = oauth.get_request_token :oauth_callback => TWITTER_CALLBACK
  session[:twitter_token]  = request_token.token
  session[:twitter_secret] = request_token.secret

  redirect request_token.authorize_url
end

get '/auth/twitter/callback' do
  oauth = OAuth::Consumer.new(
    TWITTER_KEY,
    TWITTER_SECRET,  
    :site => 'https://api.twitter.com',
    :scheme => :header,
    :http_method => :post,
    :request_token_path => "/oauth/request_token",
    :access_token_path => "/oauth/access_token",
    :authorize_path => "/oauth/authorize"
  )

  request_token = OAuth::RequestToken.new(oauth, session[:twitter_token], session[:twitter_secret])
  access_token = oauth.get_access_token(request_token, :oauth_verifier => params[:oauth_verifier])

  oauth = OAuth::Consumer.new(TWITTER_KEY, TWITTER_SECRET, { :site => 'https://api.twitter.com'})
  response = oauth.request(:get, '/1.1/account/verify_credentials.json', access_token, { scheme: :query_string })
  response_json = JSON.parse(response.body)

  # check if user is already logged in with linkedin
  if session[:linkedin]
    user = User.find_by(linkedin_id: session[:linkedin])
    user.avatar_url ||= response_json["profile_image_url_https"].gsub("_normal", '')
    user.twitter_id = response_json["id"]
    user.twitter_username = response_json["screen_name"]
  else
    user = User.find_or_initialize_by(twitter_username: response_json["screen_name"]) do |u|
      u.avatar_url = response_json["profile_image_url_https"].gsub("_normal", '')
      u.twitter_id = response_json["id"]
      u.twitter_username = response_json["screen_name"]
    end
  end

  user.twitter_access_token = access_token.token
  user.twitter_token_secret = access_token.secret
  user.twitter_profile_raw = response.body

  puts response_json.inspect

  if user.save
    session[:twitter] = user.twitter_username
    redirect "/sync/twitter"
  else
    "failed to create user account!"
  end
end

get '/sync/twitter' do
  forced = params[:force] == 'true'
  u = User.find_by(twitter_username: session[:twitter])

  client = Twitter::REST::Client.new do |config|
    config.consumer_key        = TWITTER_KEY
    config.consumer_secret     = TWITTER_SECRET
    config.access_token        = u.twitter_access_token
    config.access_token_secret = u.twitter_token_secret
  end
  
  begin
    query = "from:#{u.twitter_username} since:2023-03-07 exclude:replies exclude:retweets"
    puts "Fetching recent tweets: #{query}\n\n"
    errors = []
    @tweets = client.search(query, result_type: "recent")

    @tweets.each do |tweet|
      puts tweet.attrs.as_json(except: :user)
      post = u.posts.find_or_initialize_by(provider: 'twitter', provider_id: tweet.id) do |p|
        p.body = tweet.text
        p.posted_at = tweet.created_at
      end
      post.provider_post_raw = tweet.attrs.as_json
      post_saved = post.save
      puts "Saving post: #{post_saved}\n\n"
      errors << post.errors if !post_saved
    end

    u.twitter_last_synced_at = DateTime.current
    u.twitter_last_error = { errors_at: DateTime.current, errors: errors }.as_json if errors.count > 0
    u.save

    if forced
      session[:twitter_forced] = true
    end

    #erb :sync
    redirect "/?errors=#{errors.count > 0}"
  rescue Twitter::Error::TooManyRequests => error
    # NOTE: Your process could go to sleep for up to 15 minutes but if you
    # retry any sooner, it will almost certainly fail with the same exception.
    sleep error.rate_limit.reset_in + 1
    retry
  end
end

# LinkedIn

get '/linkedin' do
  erb 'Coming Soon'
end

get "/auth/linkedin" do
  session[:linkedin_state] = SecureRandom.uuid

  redirect "https://www.linkedin.com/oauth/v2/authorization?response_type=code&client_id=#{LINKEDIN_KEY}&redirect_uri=#{LINKEDIN_CALLBACK}&state=#{session[:linkedin_state]}&scope=#{LINKEDIN_SCOPE}"
end

get "/auth/linkedin/callback" do
  if params[:state] != session[:linkedin_state]
    puts "#{params[:state]} // #{session[:linkedin_state]}"
    halt 401, "Unauthorized"
  end

  if params[:error]
    puts "Error: #{params[:error]} // #{params[:error_description]}"
    redirect "/"
  end

  puts "Code: #{params[:code]}"

  response = ::HTTParty.post("https://www.linkedin.com/oauth/v2/accessToken?grant_type=authorization_code&code=#{params[:code]}&redirect_uri=#{LINKEDIN_CALLBACK}&client_id=#{LINKEDIN_KEY}&client_secret=#{LINKEDIN_SECRET}", {
    headers: {
      "Content-Type" => "x-www-form-urlencoded"
    }
  })

  puts response.inspect

  puts "\nAccess Token: #{response["access_token"]}\n"

  profile = ::HTTParty.get('https://api.linkedin.com/v2/me', {
    headers: {
      'Authorization' => "Bearer #{response["access_token"]}"
    }
  })

  puts profile.parsed_response.inspect

  erb profile.parsed_response.inspect

  if session[:twitter]
    user = User.find_by(twitter_username: session[:twitter])
    # use existing user!
  else
    # create new user!
  end
=begin
  user = User.find_or_initialize_by(linkedin_username: response_json["name"]) do |u|
    u.avatar_url ||= response_json["profile_image_url_https"]
    u.linkedin_id = response_json["id"]
    u.linkedin_username = response_json["screen_name"]
  end
  user.linkedin_access_token = response["access_token"]
  user.linkedin_profile_raw = profile.parsed_response

  puts response_json.inspect

  if user.save
    session[:linkedin] = user.linkedin_username
    redirect "/sync/linkedin"
  else
    "failed to create user account!"
  end
=end
end
