require 'open-uri'
require 'readability'
require 'nokogiri'
# Explores news article URL given metadata [title, url, uuid] and also does some postprocessing
class WebPageCrawler
  JS_ESCAPE_MAP   =   { '\\' => '\\\\', '</' => '<\/', "\r\n" => '\n', "\n" => '\n', "\r" => '\n', '"' => '\\"', "'" => "\\'" }
  HTML_TAGS_REGEX = /<\/?\[^<>]*\/?>/

  attr_accessor :data
  attr_accessor :doc

  def initialize feed_metadata
    @data = feed_metadata
    init_doc
  end

  def init_doc
    page = open(@data[:url])
    @doc = Readability::Document.new(page).content
  end

  def remove_tags text
    Nokogiri::HTML(text).xpath("//text()").text
  end

  def remove_redundant_spaces text
    text.squeeze
  end

  def escape_js text
    text.gsub(/(\|<\/|\r\n|\342\200\250|\342\200\251|[\n\r"'])/u) {|match| JS_ESCAPE_MAP[match] }
  end

  def process_doc
    @data.merge({body: remove_redundant_spaces(remove_tags(escape_js(doc)))})
  end
end
