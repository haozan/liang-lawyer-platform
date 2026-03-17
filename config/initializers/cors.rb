# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin AJAX requests.

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Read allowed origins from environment variable
    origins ENV.fetch('ALLOWED_ORIGINS', 'http://localhost:3000').split(',')

    resource '/api/*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true,  # Allow cookies and authentication headers
      max_age: 600        # Cache preflight requests for 10 minutes
  end
end
