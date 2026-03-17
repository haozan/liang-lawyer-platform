Rails.application.config.session_store :cookie_store,
  key: '_clacky_app_session',
  secure: Rails.env.production?,          # HTTPS-only in production
  httponly: true,                         # Prevent JavaScript access
  same_site: :lax,                        # CSRF protection
  expire_after: 14.days                   # Session expiration
