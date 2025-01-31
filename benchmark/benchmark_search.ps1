# Search Benchmark Script
$env:REDIS_HOST = "localhost"
$env:REDIS_PORT = 6379
$env:VALKEY_PORT = 6378
$env:DRAGONFLY_PORT = 6377

# Function to check if RediSearch is available
function Test-RediSearch {
    param (
        [string]$Port,
        [string]$Service
    )
    
    Write-Host "`nChecking RediSearch on $Service (port $Port)..."
    $modules = docker run --rm --network host redis:7.2 redis-cli -h localhost -p $Port MODULE LIST
    if ($modules -match "search") {
        Write-Host " RediSearch module found"
        return $true
    }
    Write-Host " RediSearch module not available"
    return $false
}

# Function to create index and sample data
function Setup-SearchIndex {
    param (
        [string]$Port,
        [string]$Service
    )
    
    Write-Host "`nSetting up test data for $Service..."
    
    # Drop existing index if any
    Write-Host "- Cleaning up old index..."
    docker run --rm --network host redis:7.2 redis-cli -h localhost -p $Port FT.DROPINDEX idx KEEPDOCS 2>$null
    Start-Sleep -Seconds 1
    
    # Create index
    Write-Host "- Creating new index..."
    $createIndex = docker run --rm --network host redis:7.2 redis-cli -h localhost -p $Port `
        FT.CREATE idx ON HASH PREFIX 1 doc: SCHEMA name TEXT SORTABLE age NUMERIC SORTABLE city TEXT SORTABLE
    
    if ($createIndex -eq "OK") {
        Write-Host " Index created successfully"
    } else {
        Write-Host " Index creation failed: $createIndex"
        return $false
    }

    # Insert sample data
    Write-Host "- Inserting test data..."
    $total = 1000
    $progress = 0
    1..$total | ForEach-Object {
        $name = "user$_"
        $age = Get-Random -Minimum 18 -Maximum 80
        $city = "city$((Get-Random -Minimum 1 -Maximum 100))"
        
        docker run --rm --network host redis:7.2 redis-cli -h localhost -p $Port `
            HSET "doc:$_" name "$name" age "$age" city "$city" | Out-Null
        
        $progress++
        if ($progress % 100 -eq 0) {
            Write-Host "  Progress: $progress/$total records"
        }
    }
    Write-Host " Data insertion complete"
    return $true
}

# Function to format search results
function Format-SearchResults {
    param (
        [string[]]$Results,
        [string]$Query,
        [int]$TimeMs
    )
    
    Write-Host "`nQuery: $Query"
    Write-Host "Time: ${TimeMs}ms"
    
    if ($Results[0] -match '^\d+$') {
        $count = [int]$Results[0]
        Write-Host "Found: $count matches"
        
        if ($count -gt 0) {
            Write-Host "`nSample results:"
            for ($i = 1; $i -lt [Math]::Min($Results.Count, 16); $i += 4) {
                $docId = $Results[$i]
                if ($i + 3 -lt $Results.Count) {
                    $fields = $Results[($i+1)..($i+3)]
                    Write-Host "  $docId : $($fields -join ' | ')"
                }
            }
        }
    } else {
        Write-Host "Error: $($Results -join ' ')"
    }
    Write-Host "-" * 80
}

# Function to run search benchmark
function Test-Search {
    param (
        [string]$Port,
        [string]$Service
    )
    
    Write-Host "`n$('=' * 80)"
    Write-Host "Benchmarking $Service (port $Port)"
    Write-Host "$('=' * 80)"
    
    # Check if RediSearch is available
    if (-not (Test-RediSearch -Port $Port -Service $Service)) {
        return
    }
    
    # Setup index and data
    if (-not (Setup-SearchIndex -Port $Port -Service $Service)) {
        Write-Host " Setup failed, skipping benchmarks"
        return
    }
    Start-Sleep -Seconds 1
    
    # Run benchmark with properly formatted commands
    Write-Host "`nRunning search tests..."
    $searches = @(
        @{
            Query = "@name:user1*"
            Description = "Prefix search"
        },
        @{
            Query = "@age:[20,30]"
            Description = "Numeric range"
        },
        @{
            Query = "@city:{city10}"
            Description = "Exact match"
        },
        @{
            Query = "(@name:user*)(@age:[25,35])"
            Description = "Combined search"
        },
        @{
            Query = "@age:[20,30]"
            Sort = "SORTBY age"
            Description = "Sorted results"
        }
    )
    
    foreach ($search in $searches) {
        Write-Host "`nTest: $($search.Description)"
        $query = $search.Query
        $sort = $search.Sort
        
        $cmd = @("FT.SEARCH", "idx", $query)
        if ($sort) {
            $cmd += $sort.Split(" ")
        }
        $cmd += @("LIMIT", "0", "5")
        
        $start = Get-Date
        $results = docker run --rm --network host redis:7.2 redis-cli -h localhost -p $Port $cmd
        $timeMs = ((Get-Date) - $start).TotalMilliseconds
        
        Format-SearchResults -Results $results -Query $query -TimeMs $timeMs
        Start-Sleep -Seconds 1
    }
}

# Test if Redis is ready
Write-Host "Testing Redis connection..."
$testResult = docker run --rm --network host redis:7.2 redis-cli -h localhost -p $env:REDIS_PORT PING
if ($testResult -ne "PONG") {
    Write-Host "Error: Redis is not responding. Please ensure Redis is running."
    exit 1
}

# Run benchmarks
Test-Search -Port $env:REDIS_PORT -Service "Redis"
Test-Search -Port $env:VALKEY_PORT -Service "Valkey"
Test-Search -Port $env:DRAGONFLY_PORT -Service "DragonflyDB"
