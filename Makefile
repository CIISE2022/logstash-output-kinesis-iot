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
	rm logstash-output-kinesis-iot-*.gem || true
	gem build logstash-output-kinesis-iot.gemspec 
	mv logstash-output-kinesis-iot-*.gem e2etest/logstash-output-kinesis-iot-latest.gem
