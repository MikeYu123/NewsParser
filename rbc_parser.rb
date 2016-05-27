require 'curb'
require 'feedjira'
require 'json'
require 'open-uri'
require 'securerandom'
require 'nokogiri'
load File.expand_path('../feed_parser.rb', __FILE__)
load File.expand_path('../neo_connector.rb', __FILE__)
load File.expand_path('../../AnalyzeNews/analysis_worker.rb', __FILE__)

class RbcParser < FeedParser
  @@url = 'http://static.feed.rbc.ru/rbc/internal/rss.rbc.ru/rbc.ru/news.rss'
  @@source = "rbc-rss"
  @@kafka_feed_topic = 'rbc_feed'
  @@articles_set = 'RBC_ARTICLES'
  def self.fetch_feed
    news = begin
        feed = Feedjira::Feed.fetch_and_parse @@url
        response = feed.entries.each do |item|
          #drop out all RBC auxillary tokens
          url = item.url.split('#')[0]
          #Checking for cachehits
          unless NeoConnector.new.match_article_url item.url
            unless is_parsed(url)
              #if no cachehit, produce new article
              article = {
                uuid: SecureRandom.uuid,
                title: item.title,
                url: url,
                body: get_body(url),
                published_datetime: item.published,
                published_unixtime: item.published.to_i
                # Not sure if needed
                # image_url: item.image
              }
              p article
              NeoConnector.new.create_article article
              json_article = article.to_json
              #TODO sidekiq
              AnalysisWorker.perform_async(json_article)
              # produce_feed @@source, json_article
              #and encache url
              set_parsed(item.url)
            else
              #Do nothing if cachehit
            end
          else
          end
        end
        # deliver_feed
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
    article_paragraphs = doc.search('div.article__text .article__text__overview, div.article__text p')
    #removing all inline metadata
    article_parts = article_paragraphs.map{|paragraph| paragraph.text}
    #RBC sometimes add empty paragraphs
    article_parts = article_parts.select{|part| part.length > 0}
    #collecting parts into one body
    article_body = article_parts.reduce{|accumulator, part| "#{accumulator}\n#{part}"}
  end
  #end of LentaParser class
end

if __FILE__ == $0
  RbcParser.fetch_feed
end
