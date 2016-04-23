require 'curb'
require 'feedjira'
require 'json'
require 'open-uri'
require 'securerandom'
require 'nokogiri'
load 'feed_parser.rb'

class IzvestiaParser < FeedParser
  @@url = 'http://izvestia.ru/xml/rss/all.xml'
  @@source = "izvestia-rss"
  # @@kafka_feed_topic = 'izvestia_feed'
  @@articles_set = 'IZVESTIA_ARTICLES'
  def self.fetch_feed
    news = begin
        feed = Feedjira::Feed.fetch_and_parse @@url
        response = feed.entries.each do |item|
          #Checking for cachehits
          unless is_parsed(item.url)
            #if no cachehit, produce new article
            article = {
              uuid: SecureRandom.uuid,
              title: item.title,
              url: item.url,
              body: get_body(item.url),
              # Not sure if needed
              # image_url: item.image
            }.to_json
            produce_feed @@source, article
            #and encache url
            set_parsed(item.url)
          else
            #Do nothing if cachehit
          end
        end
        deliver_feed
    rescue Faraday::ConnectionFailed => e
      {}.to_json
    end
  end

  def self.get_body url
    #open-uri stores intermediate data in temporary file
    temp_file = open(url)
    # reading tmp file to string
    html_response = temp_file.read
    #Grabbing data
    doc = Nokogiri::HTML.parse html_response
    #IDEA: Divided articles can be analyzed partitioned
    article_paragraphs = doc.search('div[itemprop="articleBody"] p, div[itemprop="articleBody"] h2')
    #removing all inline metadata
    article_parts = article_paragraphs.map{|paragraph| paragraph.text}
    #Izvestia add "read more" link at the end of message
    article_parts = article_parts.select{|part| !part.start_with 'Читайте также'}
    #collecting parts into one body
    article_body = article_parts.reduce{|accumulator, part| "#{accumulator}\n#{part}"}
  end
  #end of LentaParser class
end
