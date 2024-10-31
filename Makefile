#!/bin/bash

test: e2etest/logstash-output-kinesis-iot-latest.gem
	rm e2etest/test_logs/*.out || true
	cd e2etest; docker compose build; docker compose up --force-recreate; cd -

publish:
	bundle install
	bundle exec rake vendor
	bundle exec rspec
	bundle exec rake publish_gem

e2etest/logstash-output-kinesis-iot-latest.gem: logstash-output-kinesis-iot.gemspec 
	gem build logstash-output-kinesis-iot.gemspec -o e2etest/logstash-output-kinesis-iot-latest.gem
