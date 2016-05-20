class GoogleFeedRunner
  CATEGORIES = ['e', 's', 't', 'b', 'w']
  REDIS_SETS = CATEGORIES.map{|category| "google_#{category}_feed"}
  TOPICS = CATEGORIES.map{|category| "gooogle_#{category}"}
  def self.run_google_feed number
    GoogleFeedProcessor.new(REDIS_SETS[number], TOPICS[number], CATEGORIES[number]).process_feed
  end
end
