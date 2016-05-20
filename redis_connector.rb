require 'redis'
class RedisConnector
  attr_accessor :host
  attr_accessor :port
  attr_accessor :set_name
  attr_accessor :redis

  def initialize set_name, host = 'localhost', port = '6379'
    @set_name = set_name
    @host = host
    @port = port
    @redis = Redis.new host: @host, port: @port
  end

  def is_parsed url
    @redis.sismember @set_name, url
  end

  def set_parsed url
    @redis.sadd @set_name, url
  end
end
