require "redis"

REDIS_POOL = ConnectionPool.new(size: 10) { Redis.new(url: "#{ENV['REDIS_URL']}/0", network_timeout: 5, ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }) }

Redis.current = Redis.new(url: "#{ENV['REDIS_URL']}/1", network_timeout: 5, ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE })
