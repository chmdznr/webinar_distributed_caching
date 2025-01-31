#!/bin/bash

# Search Benchmark Script
export REDIS_HOST="localhost"
export REDIS_PORT=6379
export VALKEY_PORT=6378
export DRAGONFLY_PORT=6377

# Function to check if RediSearch is available
check_redisearch() {
    local port=$1
    local service=$2
    
    echo -e "\nChecking RediSearch on $service (port $port)..."
    modules=$(docker run --rm --network host redis:7.2 redis-cli -h localhost -p $port MODULE LIST)
    if echo "$modules" | grep -q "search"; then
        echo "✓ RediSearch module found"
        return 0
    fi
    echo "✗ RediSearch module not available"
    return 1
}

# Function to create index and sample data
setup_search_index() {
    local port=$1
    local service=$2
    
    echo -e "\nSetting up test data for $service..."
    
    # Drop existing index if any
    echo "- Cleaning up old index..."
    docker run --rm --network host redis:7.2 redis-cli -h localhost -p $port FT.DROPINDEX idx KEEPDOCS 2>/dev/null
    sleep 1
    
    # Create index
    echo "- Creating new index..."
    create_index=$(docker run --rm --network host redis:7.2 redis-cli -h localhost -p $port \
        FT.CREATE idx ON HASH PREFIX 1 doc: SCHEMA name TEXT SORTABLE age NUMERIC SORTABLE city TEXT SORTABLE)
    
    if [ "$create_index" = "OK" ]; then
        echo "✓ Index created successfully"
    else
        echo "✗ Index creation failed: $create_index"
        return 1
    fi

    # Insert sample data
    echo "- Inserting test data..."
    total=1000
    progress=0
    for i in $(seq 1 $total); do
        name="user$i"
        age=$((RANDOM % 62 + 18))  # Random age between 18 and 80
        city="city$((RANDOM % 100 + 1))"
        
        docker run --rm --network host redis:7.2 redis-cli -h localhost -p $port \
            HSET "doc:$i" name "$name" age "$age" city "$city" >/dev/null
        
        progress=$((progress + 1))
        if [ $((progress % 100)) -eq 0 ]; then
            echo "  Progress: $progress/$total records"
        fi
    done
    echo "✓ Data insertion complete"
    return 0
}

# Function to format search results
format_search_results() {
    local query="$1"
    local time_ms="$2"
    shift 2
    local results=("$@")
    
    echo -e "\nQuery: $query"
    echo "Time: ${time_ms}ms"
    
    if [[ ${results[0]} =~ ^[0-9]+$ ]]; then
        local count=${results[0]}
        echo "Found: $count matches"
        
        if [ $count -gt 0 ]; then
            echo -e "\nSample results:"
            local i=1
            while [ $i -lt ${#results[@]} ] && [ $i -lt 16 ]; do
                local doc_id=${results[$i]}
                if [ $((i + 3)) -lt ${#results[@]} ]; then
                    echo "  $doc_id : ${results[$((i+1))]} | ${results[$((i+2))]} | ${results[$((i+3))]}"
                fi
                i=$((i + 4))
            done
        fi
    else
        echo "Error: ${results[*]}"
    fi
    printf '%*s\n' "${COLUMNS:-80}" '' | tr ' ' -
}

# Function to run search benchmark
test_search() {
    local port=$1
    local service=$2
    
    echo -e "\n$(printf '%*s\n' "${COLUMNS:-80}" '' | tr ' ' =)"
    echo "Benchmarking $service (port $port)"
    echo "$(printf '%*s\n' "${COLUMNS:-80}" '' | tr ' ' =)"
    
    # Check if RediSearch is available
    if ! check_redisearch "$port" "$service"; then
        return
    fi
    
    # Setup index and data
    if ! setup_search_index "$port" "$service"; then
        echo "✗ Setup failed, skipping benchmarks"
        return
    fi
    sleep 1
    
    # Run benchmark with properly formatted commands
    echo -e "\nRunning search tests..."
    
    # Define search patterns
    declare -A searches
    searches[0]="@name:user1*|Prefix search"
    searches[1]="@age:[20,30]|Numeric range"
    searches[2]="@city:{city10}|Exact match"
    searches[3]="(@name:user*)(@age:[25,35])|Combined search"
    searches[4]="@age:[20,30]|Sorted results|SORTBY age"
    
    for search in "${searches[@]}"; do
        IFS='|' read -r query description sort <<< "$search"
        echo -e "\nTest: $description"
        
        cmd=("FT.SEARCH" "idx" "$query")
        if [ -n "$sort" ]; then
            cmd+=($sort)
        fi
        cmd+=("LIMIT" "0" "5")
        
        start=$(date +%s%N)
        results=($(docker run --rm --network host redis:7.2 redis-cli -h localhost -p $port "${cmd[@]}"))
        end=$(date +%s%N)
        time_ms=$(( (end - start) / 1000000 ))
        
        format_search_results "$query" "$time_ms" "${results[@]}"
        sleep 1
    done
}

# Test if Redis is ready
echo "Testing Redis connection..."
test_result=$(docker run --rm --network host redis:7.2 redis-cli -h localhost -p $REDIS_PORT PING)
if [ "$test_result" != "PONG" ]; then
    echo "Error: Redis is not responding. Please ensure Redis is running."
    exit 1
fi

# Run benchmarks
test_search $REDIS_PORT "Redis"
test_search $VALKEY_PORT "Valkey"
test_search $DRAGONFLY_PORT "DragonflyDB"
