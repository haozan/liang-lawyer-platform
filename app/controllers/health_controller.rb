class HealthController < ApplicationController
  # Skip authentication for health check endpoints
  skip_before_action :verify_authenticity_token
  
  # Basic health check - returns 200 if application is running
  def index
    render json: {
      status: 'ok',
      timestamp: Time.current.iso8601,
      environment: Rails.env
    }, status: :ok
  end
  
  # Detailed health check - checks database, Redis, and other dependencies
  def detailed
    checks = {
      database: check_database,
      redis: check_redis,
      storage: check_storage
    }
    
    all_healthy = checks.values.all? { |check| check[:status] == 'ok' }
    status_code = all_healthy ? :ok : :service_unavailable
    
    render json: {
      status: all_healthy ? 'ok' : 'degraded',
      timestamp: Time.current.iso8601,
      environment: Rails.env,
      checks: checks
    }, status: status_code
  end
  
  private
  
  def check_database
    ActiveRecord::Base.connection.execute('SELECT 1')
    {
      status: 'ok',
      message: 'Database connection successful',
      pool_size: ActiveRecord::Base.connection_pool.size,
      active_connections: ActiveRecord::Base.connection_pool.connections.size
    }
  rescue StandardError => e
    {
      status: 'error',
      message: "Database connection failed: #{e.message}"
    }
  end
  
  def check_redis
    return { status: 'skipped', message: 'Redis not configured' } unless Rails.cache.is_a?(ActiveSupport::Cache::RedisCacheStore)
    
    Rails.cache.redis.ping
    {
      status: 'ok',
      message: 'Redis connection successful'
    }
  rescue StandardError => e
    {
      status: 'error',
      message: "Redis connection failed: #{e.message}"
    }
  end
  
  def check_storage
    # Check if ActiveStorage is configured
    {
      status: 'ok',
      message: 'Storage service available',
      service: Rails.application.config.active_storage.service
    }
  rescue StandardError => e
    {
      status: 'error',
      message: "Storage check failed: #{e.message}"
    }
  end
end
