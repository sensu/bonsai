
REDIS_POOL = ConnectionPool.new(size: 10) { Redis.new(url: "#{ENV['REDIS_URL']}/0", network_timeout: 5) }

Redis.current = Redis.new(url: "#{ENV['REDIS_URL']}/1", network_timeout: 5)