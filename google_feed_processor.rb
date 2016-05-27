load File.expand_path('../redis_connector.rb', __FILE__)
load File.expand_path('../neo_connector.rb', __FILE__)
load File.expand_path('../kafka_producer.rb', __FILE__)
load File.expand_path('../google_rss_reader.rb', __FILE__)
load File.expand_path('../web_page_crawler.rb', __FILE__)
load File.expand_path('../../AnalyzeNews/analysis_worker.rb', __FILE__)
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
      unless @redis_connector.is_parsed(data[:url])
        unless(@neo_connector.match_article_url data[:url])
          article = WebPageCrawler.new(data).process_doc
          p article
          @neo_connector.create_article article
          json_article = article.to_json
          AnalysisWorker.perform_async(json_article)
          # @kafka_producer.produce_message "google_rss_#{@google_rss_reader.topic}", json_article
          # @kafka_producer.deliver_feed
          @redis_connector.set_parsed(article[:url])
        end
      end
    end
  end
end
