# Redis Benchmark Script
$env:REDIS_HOST = "localhost"
$env:REDIS_PORT = 6379

# Basic SET/GET operations
docker run --rm --network host `
  redis:7.2 `
  redis-benchmark -h $env:REDIS_HOST -p $env:REDIS_PORT -t set,get -n 100000 -c 50
