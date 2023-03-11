class User < ActiveRecord::Base
  has_many :posts

  def posts_by_date(date)
    #posts.where("posted_at >= ? AND posted_at < ?", DateTime.parse("#{date}") + PROGRAM_HOUR_OFFSET.to_i.seconds, DateTime.parse("#{date}") + PROGRAM_HOUR_OFFSET.to_i.seconds + 1.day)
    posts.where("DATE(posted_at) = ?", date)
  end
end
