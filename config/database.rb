 # in config/database.rb
 # set the database based on the current environment
 # The name in the below line is because my main app controller class in app.rb
database_name = "bipf-leaderboard-#{App.environment}"
db = URI.parse( ENV['DATABASE_URL'] || "postgres://localhost/#{database_name}")

 # connect ActiveRecord with the current database
ActiveRecord::Base.establish_connection(
 :adapter => db.scheme == "postgres" ? "postgresql" : db.scheme,
 :host => db.host,
 :port => db.port,
 :username => db.user,
 :password => db.password,
 :database => "#{database_name}",
 :encoding => "utf8"
)