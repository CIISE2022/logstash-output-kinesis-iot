# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"

# An example output that does nothing.
class LogStash::Outputs::KinesisIOT < LogStash::Outputs::Base
  config_name "kinesis-iot"
  # The name of the stream to send data to.
  config :stream_name, :validate => :string, :required => true
  # A list of event data keys to use when constructing a partition key
  config :event_partition_keys, :validate => :array, :default => []
  # If true, a random partition key will be assigned to each log record
  config :randomized_partition_key, :validate => :boolean, :default => false
  # If the number of records pending being written to Kinesis exceeds this number, then block
  # Logstash processing until they're all written.
  config :max_pending_records, :validate => :number, :default => 1000

  # An AWS certificate key to use for authentication to AWS IOT
  config :cert_file, :validate => :string, :required => true
  # An AWS secret key to use for authentication to AWS IOT
  config :key_file, :validate => :string, :required => true
  # The AWS root CA certificate for mTLS
  config :ca_cert_file, :validate => :string, :required => true
  # The AWS IOT endpoint to use to get the kineisis role  
  config :iot_endpoint, :validate => :string, :required => true
  # The thing name to use to get the kineisis role  
  config :iot_name, :validate => :string, :required => true

  # If provided, use this AWS access key for authentication to CloudWatch
  config :metrics_access_key, :validate => :string
  # If provided, use this AWS secret key for authentication to CloudWatch
  config :metrics_secret_key, :validate => :string
  # If provided, STS will be used to assume this role and use it to authenticate to CloudWatch
  config :metrics_role_arn, :validate => :string

  config :sts_proxy_host, :validate => :string
  config :sts_proxy_port, :validate => :number

  config :aggregation_enabled, :validate => :boolean, :default => true
  config :aggregation_max_count, :validate => :number, :default => 4294967295
  config :aggregation_max_size, :validate => :number, :default => 51200
  config :cloudwatch_endpoint, :validate => :string, :default => nil
  config :cloudwatch_port, :validate => :number, :default => 443
  config :collection_max_count, :validate => :number, :default => 500
  config :collection_max_size, :validate => :number, :default => 5242880
  config :connect_timeout, :validate => :number, :default => 6000
  config :credentials_refresh_delay, :validate => :number, :default => 5000
  config :enable_core_dumps, :validate => :boolean, :default => false
  config :fail_if_throttled, :validate => :boolean, :default => false
  config :kinesis_endpoint, :validate => :string, :default => nil
  config :kinesis_port, :validate => :number, :default => 443
  config :log_level, :validate => ["info", "warning", "error"], :default => "info"
  config :max_connections, :validate => :number, :default => 4
  config :metrics_granularity, :validate => ["global", "stream", "shard"], :default => "shard"
  config :metrics_level, :validate => ["none", "summary", "detailed"], :default => "detailed"
  config :metrics_namespace, :validate => :string, :default => "KinesisProducerLibrary"
  config :metrics_upload_delay, :validate => :number, :default => 60000
  config :min_connections, :validate => :number, :default => 1
  config :native_executable, :validate => :string, :default => nil
  config :rate_limit, :validate => :number, :default => 150
  config :record_max_buffered_time, :validate => :number, :default => 100
  config :record_ttl, :validate => :number, :default => 30000
  config :region, :validate => :string, :required => true
  config :request_timeout, :validate => :number, :default => 6000
  config :temp_directory, :validate => :string, :default => nil
  config :verify_certificate, :validate => :boolean, :default => true

  def check_required_file(file)
    raise "Required file " + file +" does not exist." unless File.file?(file)
  end

  public
  def register
    check_required_file(@cert_file)
    check_required_file(@key_file)
    check_required_file(@ca_cert_file)
    @logger.error("Kinesis_IOT PLugin is empty")
  end # def register

  public
  def receive(event)
    return "Event received"
  end # def event
end # class LogStash::Outputs::Example
