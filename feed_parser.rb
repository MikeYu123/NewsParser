require 'redis'
require 'ruby-kafka'

class FeedParser
  ##TODO: contruct config.yml with host and port
  @@redis = Redis.new
  ##TODO: contruct config.yml with set name
  @@articles_set = 'ARTICLES'
  ##TODO: contruct config.yml with kafka settings

  def self.is_parsed url
    @@redis.sismember @@articles_set, url
  end

  def self.set_parsed url
    @@redis.sadd @@articles_set, url
  end
end
