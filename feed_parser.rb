require 'redis'
require 'ruby-kafka'

class FeedParser
  ##TODO: contruct config.yml with host and port
  @@redis = Redis.new
  ##TODO: contruct config.yml with set name
  @@articles_set = 'ARTICLES'
  ##TODO: contruct config.yml with kafka settings
  @@kafka = Kafka.new(seed_brokers: ["localhost:9092"])
  @@kafka_producer = @@kafka.producer
  @@kafka_feed_topic = 'parsed_feed'

  def self.is_parsed url
    @@redis.sismember @@articles_set, url
  end

  def self.set_parsed url
    @@redis.sadd @@articles_set, url
  end

  def self.produce_feed key, message
    @@kafka_producer.produce message, key: key, topic: @@kafka_feed_topic
  end

  def self.deliver_feed
    @@kafka_producer.deliver_messages
  end
end
