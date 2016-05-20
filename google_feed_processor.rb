load 'redis_connector.rb'
load 'neo_connector.rb'
load 'kafka_producer.rb'
load 'google_rss_reader.rb'
load 'web_page_crawler.rb'
require 'json'

class GoogleFeedProcessor
  attr_accessor :redis_connector
  attr_accessor :kafka_producer
  attr_accessor :neo_connector
  attr_accessor :google_rss_reader

  def initialize redis_set_name, kafka_feed_topic_name, category
    @redis_connector = RedisConnector.new(redis_set_name)
    @kafka_producer = KafkaProducer.new(kafka_feed_topic_name)
    @neo_connector = NeoConnector.new
    @google_rss_reader = GoogleRSSReader.new category
  end

  def process_feed
    metadata = @google_rss_reader.read_rss
    metadata.each do |data|
      unless @redis_connector.is_parsed(data.url)
        unless(@neo_connector.match_article_url data.url)
          article = WebPageCrawler.new(data).process_doc
          NeoConnector.new.create_article article
          json_article = article.to_json
          @kafka_producer.produce_message @@source, json_article
          @kafka_producer.deliver_feed
          @redis_connector.set_parsed(article.url)
        end
      end
    end
  end
end
