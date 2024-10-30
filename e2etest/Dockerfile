FROM opensearchproject/logstash-oss-with-opensearch-output-plugin:8.9.0

RUN logstash-plugin install logstash-output-opensearch

ENV lsplugins=""
#logstash-input-relp logstash-input-google_pubsub logstash-filter-tld logstash-filter-rest logstash-filter-json_encode logstash-filter-cidr logstash-filter-split logstash-filter-translate microsoft-logstash-output-azure-loganalytics"


COPY logstash-output-kinesis-iot-latest.gem /tmp/
RUN logstash-plugin install /tmp/logstash-output-kinesis-iot-latest.gem
RUN logstash-plugin list --verbose; sleep 2

# Add your logstash plugins setup here
# Example: RUN logstash-plugin install logstash-filter-json
RUN for lsplugin in ${lsplugins}; do logstash-plugin install ${lsplugin} ; done
