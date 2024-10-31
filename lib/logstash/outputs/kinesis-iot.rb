# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"
require "time"
require "json"
require 'aws-sdk-kinesis'


# An example output that does nothing.
class LogStash::Outputs::KinesisIOT < LogStash::Outputs::Base
  config_name "kinesis-iot"
  default :codec, 'json'
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

  AWSIOTCreds = Struct.new(:accessKeyId, :secretAccessKey, :sessionToken, :expiration)
  def getIotAccess
    uri = URI(@iot_endpoint)
  
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.cert = OpenSSL::X509::Certificate.new(File.read(@cert_file))
    http.key = OpenSSL::PKey::RSA.new(File.read(@key_file))
    http.ca_file = @ca_cert_file
    http.verify_mode = @verify_certificate ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE  

    request = Net::HTTP::Get.new(uri)
    request['x-amzn-iot-thingname'] = @iot_name

    response = http.request(request)
    result = JSON.parse(response.body)["credentials"]
    @logger.info("Credentials expire at " +Time.parse(result["expiration"]).to_s)
    return AWSIOTCreds.new(result["accessKeyId"], result["secretAccessKey"], result["sessionToken"],
                           Time.parse(result["expiration"]))
  end
  
  def init_aws
    Aws.config.update({
      region: @region,
      credentials: Aws::Credentials.new(@creds.accessKeyId, @creds.secretAccessKey, @creds.sessionToken)
    })
    # Initialize Kinesis client
    @logger.info("Set AWS Credentials")
    @kinesis = Aws::Kinesis::Client.new
      # send data to kinesis
  end


  public
  def register
    check_required_file(@cert_file)
    check_required_file(@key_file)
    check_required_file(@ca_cert_file)
    @creds = getIotAccess()
    init_aws()
    @codec.on_event(&method(:send_record))
  end # def register

  public
  def receive(event)
    return unless output?(event)

    if @randomized_partition_key
      event.set("[@metadata][partition_key]", SecureRandom.uuid)
    else
      # Haha - gawd. If I don't put an empty string in the array, then calling .join()
      # on it later will result in a US-ASCII string if the array is empty. Ruby is awesome.
      partition_key_parts = [""]

      @event_partition_keys.each do |partition_key_name|
        if not event.get(partition_key_name).nil? and event.get(partition_key_name).length > 0
          partition_key_parts << event.get(partition_key_name).to_s
          break
        end
      end

      event.set("[@metadata][partition_key]", (partition_key_parts * "-").to_s[/.+/m] || "-")
    end

    begin
      @codec.encode(event)
    rescue => e
      @logger.warn("Error encoding event", :exception => e, :event => event)
    end
  end
  def send_record(event, payload)
    if @creds.expiration >= Time.now() + 1
      @logger.debug("Token still valid at " + (Time.now() +1 ).to_s)
    else
      @logger.debug("Invalid token, renewing")
      @creds = getIotAccess()
      init_aws()
    end
    begin
      init_aws() unless @creds.expiration >= Time.now() + 1
      response = @kinesis.put_record({
        stream_name: @stream_name,
        data: payload,
        partition_key: event.get("[@metadata][partition_key]")
      })
      @logger.debug("Record sent successfully. Shard ID: #{response.shard_id}, Sequence number: #{response.sequence_number}")
    rescue => e
      @logger.warn("Error writing event to Kinesis", :exception => e)
    end

    # num = @producer.getOutstandingRecordsCount()
    # if num > @max_pending_records
    #   @logger.warn("Kinesis is too busy - blocking until things have cleared up")
    #   @producer.flushSync()
    #   @logger.info("Okay - I've stopped blocking now")
    # end
  end
end # class LogStash::Outputs::Example
