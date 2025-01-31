#!/bin/bash

# Valkey Benchmark Script
export VALKEY_HOST="localhost"
export VALKEY_PORT=6378

# Basic SET/GET operations
docker run --rm --network host \
  redis:7.2 \
  redis-benchmark -h $VALKEY_HOST -p $VALKEY_PORT -t set,get -n 100000 -c 50
