require 'sidekiq'
require 'sidekiq-status'

Sidekiq.default_worker_options = {
  backtrace: true
}

#redis_queue = {url: "#{ENV['REDIS_URL']}/0", network_timeout: 5}

Sidekiq.configure_server do |config|
  config.redis = REDIS_POOL
  Redis.current = Redis.new(url: "#{ENV['REDIS_URL']}/1", network_timeout: 5)
  Sidekiq::Status.configure_server_middleware config, expiration: 7.days
  Sidekiq::Status.configure_client_middleware config, expiration: 7.days
end

Sidekiq.configure_client do |config|
  config.redis = REDIS_POOL
  Sidekiq::Status.configure_client_middleware config, expiration: 30.minutes
end

Sidekiq::Extensions.enable_delay!