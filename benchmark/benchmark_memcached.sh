#!/bin/bash

# Memcached Benchmark Script
export MEMCACHED_HOST="localhost"
export MEMCACHED_PORT=11211

# Run benchmark in Docker container
docker run --rm --network host \
  redislabs/memtier_benchmark:latest \
  -s $MEMCACHED_HOST -p $MEMCACHED_PORT \
  --protocol=memcache_text \
  --requests=100000 \
  --clients=50 \
  --threads=4 \
  --ratio=1:1 \
  --data-size=32
