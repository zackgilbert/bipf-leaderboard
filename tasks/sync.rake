
task :twitter do
  return if Date.parse(PROGRAM_END_DATE) < Date.current
  puts "Starting sync twitter rake task: #{Date.current}"

  errors = []

  User.where.not(twitter_username: nil).each do |u|
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = TWITTER_KEY
      config.consumer_secret     = TWITTER_SECRET
      config.access_token        = u.twitter_access_token
      config.access_token_secret = u.twitter_token_secret
    end

    begin
      query = "from:#{u.twitter_username} since:#{u.twitter_last_synced_at} exclude:replies exclude:retweets"
      puts "Fetching recent tweets: #{query}\n\n"
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
    rescue Twitter::Error::TooManyRequests => error
      # NOTE: Your process could go to sleep for up to 15 minutes but if you
      # retry any sooner, it will almost certainly fail with the same exception.
      sleep error.rate_limit.reset_in + 1
      retry
    end
  end

  puts errors.inspect
end
