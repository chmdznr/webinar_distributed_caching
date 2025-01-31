# Distributed Caching Webinar Benchmark

This repository contains benchmark scripts for various distributed caching systems, including Dragonfly, Valkey, Memcached, and Redis.

## System Requirements
- Docker Desktop for Windows
- One of the following environments:
  - PowerShell 7+ (Windows)
  - Git Bash or WSL (for Bash scripts)

## Setup

### 1. Start Services
```bash
docker-compose up -d
```

### 2. Choose Your Environment

#### Option A: PowerShell
Run benchmarks using PowerShell scripts:
```powershell
# Basic benchmarks
.\benchmark_redis.ps1
.\benchmark_memcached.ps1
.\benchmark_valkey.ps1
.\benchmark_dragonfly.ps1

# Full text search benchmarks
.\benchmark_search.ps1
```

#### Option B: Bash
First, make the scripts executable:
```bash
chmod +x *.sh
```

Then run the benchmarks:
```bash
# Basic benchmarks
./benchmark_redis.sh
./benchmark_memcached.sh
./benchmark_valkey.sh
./benchmark_dragonfly.sh

# Full text search benchmarks
./benchmark_search.sh
```

## Benchmark Types

### Basic Operations
- SET/GET performance for Redis, Valkey, and DragonflyDB
- SET/GET with memtier_benchmark for Memcached
- All tests run with 100,000 operations and 50 concurrent clients

### Full Text Search (RediSearch)
Tests various search capabilities:
1. Prefix search: `@name:user1*`
2. Numeric range: `@age:[20,30]`
3. Exact match: `@city:{city10}`
4. Combined search: `(@name:user*)(@age:[25,35])`
5. Sorted results: `@age:[20,30] SORTBY age`

Note: Full text search is only available on Redis with RediSearch module. Some features might not be supported by all services.

## Viewing Results
- Basic benchmarks show operations per second and latency metrics
- Search benchmarks display:
  - Number of matches
  - Sample results
  - Query execution time
  - Any errors or unsupported features

## Cleanup
Stop all services and remove volumes:
```bash
docker-compose down -v
```

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License

[MIT](https://choosealicense.com/licenses/mit/)
