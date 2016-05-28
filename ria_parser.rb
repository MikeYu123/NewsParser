require 'curb'
require 'feedjira'
require 'json'
require 'open-uri'
require 'securerandom'
require 'nokogiri'
load File.expand_path('../feed_parser.rb',__FILE__)
load File.expand_path('../neo_connector.rb',__FILE__)
load File.expand_path('../../AnalyzeNews/analysis_worker.rb', __FILE__)


class Feedjira::Parser::ITunesRSSItem
  element 'category', :as => :category
end

class RiaParser < FeedParser
  @@urls = ["http://ria.ru/export/rss2/index.xml",
     "http://ria.ru/export/rss2/politics/index.xml",
     "http://ria.ru/export/rss2/world/index.xml", "http://ria.ru/export/rss2/economy/index.xml",
     "http://ria.ru/export/rss2/society/index.xml",
      "http://ria.ru/export/rss2/education/index.xml",
       "http://ria.ru/export/rss2/moscow/index.xml", "http://sport.ria.ru/export/rss2/sport/index.xml",
       "http://ria.ru/export/rss2/incidents/index.xml",
       "http://ria.ru/export/rss2/defense_safety/index.xml",
       "http://ria.ru/export/rss2/science/index.xml",
        "http://eco.ria.ru/export/rss2/eco/index.xml",
        "http://ria.ru/export/rss2/tourism/index.xml",
        "http://ria.ru/export/rss2/culture/index.xml",
         "http://ria.ru/export/rss2/announce/index.xml",
         "http://ria.ru/export/rss2/spravka/index.xml",
         "http://ria.ru/export/rss2/photolents/index.xml",
          "http://ria.ru/export/rss2/video/index.xml"]

  @@source = "ria-rss"
  @@articles_set = 'RIA_ARTICLES'
  def self.fetch_feed
    news = begin
      @@urls.each do |url|
        feed = Feedjira::Feed.fetch_and_parse url
        response = feed.entries.each do |item|
          #Checking for cachehits
          unless is_parsed(item.url)
            unless NeoConnector.new.match_article_url item.url
              #if no cachehit, produce new article
              article = {
                uuid: SecureRandom.uuid,
                title: item.title,
                url: item.url,
                body: get_body(item.url),
                published_datetime: item.published,
                published_unixtime: item.published.to_i
                # Not sure if needed
                # image_url: item.image
              }
              NeoConnector.new.create_article article
              json_article = article.to_json
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
      end
        # deliver_feed
    rescue Faraday::ConnectionFailed => e
      {}.to_json
    end
  end

  def self.get_body url
    begin
      #open-uri stores intermediate data in temporary file
      temp_file = open(url)
      # reading tmp file to string
      html_response = temp_file.read
      #Grabbing data
      doc = Nokogiri::HTML.parse html_response
      #IDEA: Divided articles can be analyzed partitioned
      article_paragraphs = doc.search('.b-article__body p')
      #removing all inline metadata
      # p article_paragraphs
      article_parts = article_paragraphs.map{|paragraph| paragraph.text}
      #Ria sometimes add empty paragraphs
      article_parts = article_parts.select{|part| part.length > 0}
      #collecting parts into one body
      article_body = article_parts.reduce{|accumulator, part| "#{accumulator}\n#{part}"}
    rescue RuntimeError
    end
  end
  #end of LentaParser class
end

if __FILE__ == $0
  RiaParser.fetch_feed
end
