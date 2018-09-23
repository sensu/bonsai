Sidekiq.default_worker_options = {
  backtrace: true
}

redis_queue = {url: "redis://#{ENV['REDIS_HOST']}/0", network_timeout: 5}

Sidekiq.configure_server do |config|
  config.redis = redis_queue
  Redis.current = Redis.new(url: "redis://#{ENV['REDIS_HOST']}/1", network_timeout: 5) 
end

Sidekiq.configure_client do |config|
  config.redis = redis_queue
end

Sidekiq::Extensions.enable_delay!
