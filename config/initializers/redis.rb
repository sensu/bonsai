redis_url = ENV.fetch("REDIS_URL", "redis://127.0.0.1:6379")

REDIS_POOL = ConnectionPool.new(size: 10) { Redis.new(url: "#{redis_url}/0", network_timeout: 5) }

Redis.current = Redis.new(url: "#{redis_url}/1", network_timeout: 5)
