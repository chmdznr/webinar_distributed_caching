#!/bin/bash

# DragonflyDB Benchmark Script
export DRAGONFLY_HOST="localhost"
export DRAGONFLY_PORT=6377

# Basic operations
docker run --rm --network host \
  redis:7.2 \
  redis-benchmark -h $DRAGONFLY_HOST -p $DRAGONFLY_PORT -t set,get -n 100000 -c 50
