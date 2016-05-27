#start single-node Kafka cluster
#TODO: config.yml
KAFKA_HOST = 'localhost'
KAFKA_PORT = 9092
ZOOKEEPER_HOST = 'localhost'
ZOOKEEPER_PORT = 2181
KAFKA_HOME = "/home/mike/kafka_2.11-0.9.0.0"
RSS_FEED_TOPICS = ['rbc_feed', 'gazeta_ru_feed', 'izvestia_feed', 'lenta_feed', 'meduza_feed', 'ria_feed']
GOOGLE_FEED_TOPICS = ['e', 's', 't', 'b', 'w'].map{|x| "google_#{x}_feed"}
#Start zookeeper
`#{KAFKA_HOME}/bin/zookeeper-server-start.sh -daemon #{KAFKA_HOME}/config/zookeeper.properties`
#Start kafka
`#{KAFKA_HOME}/bin/kafka-server-start.sh -daemon #{KAFKA_HOME}/config/server.properties`
#create_topics
RSS_FEED_TOPICS.each do |feed|
  `#{KAFKA_HOME}/bin/kafka-topics.sh --create --zookeeper #{ZOOKEEPER_HOST}:#{ZOOKEEPER_PORT} --replication-factor 1 --partitions 1 --topic #{feed}`
end

GOOGLE_FEED_TOPICS.each do |feed|
  `#{KAFKA_HOME}/bin/kafka-topics.sh --create --zookeeper #{ZOOKEEPER_HOST}:#{ZOOKEEPER_PORT} --replication-factor 1 --partitions 1 --topic #{feed}`
end
