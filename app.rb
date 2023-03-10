require 'dotenv'
require 'rubygems'
require 'sinatra'
require 'sinatra/activerecord'
require './config/environment'
require 'oauth'
require 'json'
require 'twitter'

Dotenv.load()

class App < Sinatra::Base

  SERVER_HOST = '0.0.0.0'
  SERVER_PORT = '3000'
  BASE_URL    = "https://93cf-2600-1700-9e20-ba0-a57f-5756-a2b6-c16.ngrok.io"

  TWITTER_KEY           = ENV['TWITTER_KEY']
  TWITTER_SECRET        = ENV['TWITTER_SECRET']
  TWITTER_OAUTH2_KEY     = ENV['TWITTER_OAUTH_KEY']
  TWITTER_OAUTH2_SECRET  = ENV['TWITTER_OAUTH_SECRET']

  TWITTER_CALLBACK = "#{BASE_URL}/auth/twitter/callback"

  GITHUB_KEY      = ''
  GITHUB_SECRET   = ''
  GITHUB_CALLBACK = "#{BASE_URL}/auth/github/callback" 

  # Sinatra settings
  enable :sessions

  set :bind, SERVER_HOST
  set :port, SERVER_PORT

  set :static, false
  set :run, true

  get '/' do
    erb :index
  end

  # Twitter

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

    puts "Token/Secret: #{request_token.token} / #{request_token.secret}"

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

    puts "Access token: #{access_token.inspect}"

    oauth = OAuth::Consumer.new(TWITTER_KEY, TWITTER_SECRET, { :site => 'https://api.twitter.com'})

    response = oauth.request(:get, '/1.1/account/verify_credentials.json', access_token, { :scheme => :query_string })
    
    response_json = JSON.parse(response.body)

    user = User.find_or_initialize_by(name: response_json["name"]) do |u|
      u.avatar_url = response_json["profile_image_url_https"].gsub("_normal", '')
      u.twitter_id = response_json["id"]
      u.twitter_username = response_json["screen_name"]
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

  get '/auth/linkedin' do
      # ...
    end

  get '/auth/linkedin/callback' do
    # ...
  end
end
