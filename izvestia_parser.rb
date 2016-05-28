require 'curb'
require 'feedjira'
require 'json'
require 'open-uri'
require 'securerandom'
require 'nokogiri'
load File.expand_path('../feed_parser.rb', __FILE__)
load File.expand_path('../neo_connector.rb', __FILE__)
load File.expand_path('../../AnalyzeNews/analysis_worker.rb', __FILE__)


class IzvestiaParser < FeedParser
  @@url = 'http://izvestia.ru/xml/rss/all.xml'
  @@source = "izvestia-rss"
  @@articles_set = 'IZVESTIA_ARTICLES'
  def self.fetch_feed
    news = begin
        feed = Feedjira::Feed.fetch_and_parse @@url
        response = feed.entries.each do |item|
          #Checking for cachehits
          unless NeoConnector.new.match_article_url item.url
            unless is_parsed(item.url)
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
      article_paragraphs = doc.search('div[itemprop="articleBody"] p, div[itemprop="articleBody"] h2')
      #removing all inline metadata
      article_parts = article_paragraphs.map{|paragraph| paragraph.text}
      #Izvestia add "read more" link at the end of message
      article_parts = article_parts.select{|part| !part.start_with? 'Читайте также'}
      #collecting parts into one body
      article_body = article_parts.reduce{|accumulator, part| "#{accumulator}\n#{part}"}
    rescue RuntimeError
    end
  end
  #end of LentaParser class
end

if __FILE__ == $0
  IzvestiaParser.fetch_feed
end
