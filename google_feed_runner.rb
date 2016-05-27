load File.expand_path('../google_feed_processor.rb', __FILE__)
class GoogleFeedRunner
  CATEGORIES = ['e', 's', 't', 'b', 'w']
  REDIS_SETS = CATEGORIES.map{|category| "GOOGLE_#{category}"}
  TOPICS = CATEGORIES.map{|category| "gooogle_#{category}_feed"}
  def self.run_google_feed number
    GoogleFeedProcessor.new(REDIS_SETS[number], TOPICS[number], CATEGORIES[number]).process_feed
  end
end
