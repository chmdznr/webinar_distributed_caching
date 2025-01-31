# DragonflyDB Benchmark Script
$env:DRAGONFLY_HOST = "localhost"
$env:DRAGONFLY_PORT = 6377

# Basic operations
docker run --rm --network host `
  redis:7.2 `
  redis-benchmark -h $env:DRAGONFLY_HOST -p $env:DRAGONFLY_PORT -t set,get -n 100000 -c 50
