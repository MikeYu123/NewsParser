require 'curb'
require 'feedjira'
require 'json'
require 'open-uri'
require 'securerandom'
require 'nokogiri'
load 'feed_parser.rb'
load 'neo_connector.rb'

class LentaParser < FeedParser
  @@url = 'https://lenta.ru/rss/'
  @@source = "lenta-rss"
  @@kafka_feed_topic = 'lenta_feed'
  @@articles_set = 'LENTA_ARTICLES'
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
            }
            NeoConnector.new.create_article article
            json_article = article.to_json
            produce_feed @@source, json_article
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
    https_url = url.gsub 'http', 'https'
    #open-uri stores intermediate data in temporary file
    temp_file = open(https_url)
    # reading tmp file to string
    html_response = temp_file.read
    #Grabbing data
    doc = Nokogiri::HTML.parse html_response
    #IDEA: Divided articles can be analyzed partitioned
    article_paragraphs = doc.search('div.b-text.clearfix[itemprop="articleBody"] p')
    #removing all inline metadata
    article_parts = article_paragraphs.map{|paragraph| paragraph.text}
    #collecting parts into one body
    article_body = article_parts.reduce{|accumulator,part| "#{accumulator}\n#{part}"}
  end
  #end of LentaParser class
end


if __FILE__ == $0
  LentaParser.fetch_feed
end
