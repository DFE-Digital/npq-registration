Rack::MiniProfiler.config.storage_options = { url: ENV["REDIS_CACHE_URL"] }
Rack::MiniProfiler.config.storage = Rack::MiniProfiler::RedisStore
