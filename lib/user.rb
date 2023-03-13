class User < ActiveRecord::Base
  has_many :posts

  attr_accessor :posts_count

  def posts_by_period(start_date, end_date)
    if timezone_offset
      posts.where("posted_at >= ? AND posted_at < ?", DateTime.parse("#{start_date}") + timezone_offset.to_i.seconds, DateTime.parse("#{end_date}") + timezone_offset.to_i.seconds + 1.day)
    else
      posts.where("DATE(posted_at) >= ? AND DATE(posted_at) <= ?", start_date, end_date)
    end
  end

  def posts_by_date(date)
    if timezone_offset
      posts.where("posted_at >= ? AND posted_at < ?", DateTime.parse("#{date}") + timezone_offset.to_i.seconds, DateTime.parse("#{date}") + timezone_offset.to_i.seconds + 1.day)
    else
      posts.where("DATE(posted_at) = ?", date)
    end
  end
end
