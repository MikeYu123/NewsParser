require 'open-uri'
require 'readability'
require 'nokogiri'
# Explores news article URL given metadata [title, url, uuid] and also does some postprocessing
class WebPageCrawler
  JS_ESCAPE_MAP   =   { '\\' => '\\\\', '</' => '<\/', "\r\n" => '\n', "\n" => '\n', "\r" => '\n', '"' => '\\"', "'" => "\\'" }
  HTML_TAGS_REGEX = /<\/?\w*\/?>/

  attr_accessor :data
  attr_accessor :doc

  def initialize feed_metadata
    @data = feed_metadata
    init_doc
  end

  def init_doc
    begin
      page = open(@data[:url]).read
      @doc = Readability::Document.new(page).content.encode("utf-8")
      p @doc
      @doc
    rescue RuntimeError
    end
  end

  def remove_tags text
    Nokogiri::HTML(text).xpath("//text()").text.gsub HTML_TAGS_REGEX, ''
  end

  def remove_redundant_spaces text
    text.squeeze
  end

  def escape_js text
    text.gsub(/(\|<\/|\r\n|\342\200\250|\342\200\251|[\n\r"'])/u) {|match| " " }
  end

  def process_doc
    @data.merge({body: remove_redundant_spaces(remove_tags(escape_js(doc)))})
  end
end
