#!/bin/bash

# Redis Benchmark Script
export REDIS_HOST="localhost"
export REDIS_PORT=6379

# Basic SET/GET operations
docker run --rm --network host \
  redis:7.2 \
  redis-benchmark -h $REDIS_HOST -p $REDIS_PORT -t set,get -n 100000 -c 50
