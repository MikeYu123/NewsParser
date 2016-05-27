require 'feedjira'
require 'securerandom'
class GoogleRSSReader
  attr_accessor :topic
  GOOGLE_URI_REGEX = /(https?\:\/\/(?!news\.google\.(com|ru))).*$/

  def initialize topic
    @topic = topic
  end

  #Returns entry hash without body
  def read_rss
    query = "http://news.google.ru/news?hl=ru&topic=#{@topic}&output=rss&ned=ru_ru&num=30&&scoring=n"
    feed = Feedjira::Feed.fetch_and_parse(query)
    feed.entries.map do |entry|
      {
        uuid: SecureRandom.uuid,
        title: entry.title,
        url: entry.url.match(GOOGLE_URI_REGEX)[0],
        published_datetime: entry.published,
        published_unixtime: entry.published.to_i
      }
    end
  end
end
