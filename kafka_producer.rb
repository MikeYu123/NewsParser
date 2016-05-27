require 'ruby-kafka'
require 'json'

class KafkaProducer
  attr_accessor :host
  attr_accessor :port
  attr_accessor :kafka
  attr_accessor :producer
  attr_accessor :topic_name

  def initialize topic_name, host='localhost', port= 9092
    @host = host
    @port = port
    @kafka = Kafka.new(seed_brokers: ["#{host}:#{port}"])
    @producer = @kafka.producer
    @topic_name = topic_name
  end

  def produce_message key, message
    @producer.produce message, key: key, topic: @topic_name
  end

  def deliver_feed
    @producer.deliver_messages
  end
end
