# Valkey Benchmark Script
$env:VALKEY_HOST = "localhost"
$env:VALKEY_PORT = 6378

# Basic SET/GET operations
docker run --rm --network host `
  redis:7.2 `
  redis-benchmark -h $env:VALKEY_HOST -p $env:VALKEY_PORT -t set,get -n 100000 -c 50
