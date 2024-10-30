#!/bin/bash

test: e2etest/logstash-output-kinesis-iot-latest.gem
	rm e2etest/test_logs/*.out
	cd e2etest; docker compose build; docker compose up; cd -

e2etest/logstash-output-kinesis-iot-latest.gem:
	gem build logstash-output-kinesis-iot.gemspec -o e2etest/logstash-output-kinesis-iot-latest.gem
