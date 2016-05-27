require 'neography'
class NeoConnector
  attr_accessor :neo
  attr_accessor :auth_type
  attr_accessor :username
  attr_accessor :password
  attr_accessor :server
  attr_accessor :port

  def initialize auth_type = 'basic', username = "neo4j", password = "root", host = 'localhost', port = 7474
    @auth_type = auth_type
    @username = username
    @password = password
    @server = host
    @port = port
    @neo = Neography::Rest.new({:authentication => @auth_type, :username => @username, :password => @password, :server => @server, :port => @port})
  end

  JS_ESCAPE_MAP   =   { '\\' => '\\\\', '</' => '<\/', "\r\n" => '\n', "\n" => '\n', "\r" => '\n', '"' => '\\"', "'" => "\\'" }
  #TODO: config.yml
  def create_article article
    query = "Create (n:Article{uuid: \'#{escape_js article[:uuid]}\', title: \'#{escape_js article[:title]}\', body: \'#{escape_js article[:body]}\', url: \'#{escape_js article[:url]}\', published_datetime: \'#{article[:published_datetime]}\', published_unixtime: #{article[:published_unixtime]}})"
    p query
    @neo.execute_query query
  end

  def match_article_url url
    checking_query = "match(n:Article) where n.url = \'#{url}\' return n.uuid"
    checking_data = @neo.execute_query(checking_query)['data']
    !checking_data.empty?
  end

  def escape_js s
    s.gsub(/(\|<\/|\r\n|\342\200\250|\342\200\251|[\n\r"'])/u){|match| JS_ESCAPE_MAP[match] } if s
  end
end
