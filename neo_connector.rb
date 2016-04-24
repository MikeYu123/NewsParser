require 'neography'
class NeoConnector
  #TODO: config.yml
  @@neo = Neography::Rest.new({:authentication => 'basic', :username => "neo4j", :password => "root"})
  def self.create_article article
    query = "Create (n:Article{uuid: \'#{article[:uuid]}\', title: \'#{article[:title]}\', body: \'#{article[:body]}\', url: \'#{article[:url]}\'})"
    # p query
    @@neo.execute_query query
  end
end
