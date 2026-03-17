threads_count = ENV.fetch("RAILS_MAX_THREADS", 5)
threads threads_count, threads_count

# Use APP_PORT from environment, fallback to PORT, then default 3000
port ENV.fetch("APP_PORT") { ENV.fetch("PORT", "3000") }

# Specifies the `environment` that Puma will run in.
environment ENV.fetch("RAILS_ENV", "development")

# Production optimization: Use workers for better performance
if ENV.fetch("RAILS_ENV", "development") == "production"
  workers ENV.fetch("WEB_CONCURRENCY", 2).to_i
  
  # Preload application for better memory efficiency
  preload_app!
  
  # Allow puma to be restarted by `bin/rails restart` command.
  plugin :tmp_restart
  
  # Worker timeout
  worker_timeout 30
  
  # Before fork callback
  before_fork do
    ActiveRecord::Base.connection_pool.disconnect! if defined?(ActiveRecord)
  end
  
  # On worker boot callback
  on_worker_boot do
    ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
  end
else
  plugin :tmp_restart
end

pidfile ENV["PIDFILE"] if ENV["PIDFILE"]
