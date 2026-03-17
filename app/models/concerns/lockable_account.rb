module LockableAccount
  extend ActiveSupport::Concern
  
  # Constants
  MAX_FAILED_ATTEMPTS = 5
  LOCK_DURATION = 30.minutes
  
  # Public methods
  
  # Increment failed login attempts and lock account if threshold is reached
  def increment_failed_attempts!
    self.failed_attempts ||= 0
    self.failed_attempts += 1
    
    if failed_attempts >= MAX_FAILED_ATTEMPTS
      lock_account!
    else
      save(validate: false)
    end
  end
  
  # Lock the account
  def lock_account!
    self.locked_at = Time.current
    self.unlock_token = SecureRandom.urlsafe_base64(15)
    save(validate: false)
  end
  
  # Unlock the account
  def unlock_account!
    self.failed_attempts = 0
    self.locked_at = nil
    self.unlock_token = nil
    save(validate: false)
  end
  
  # Check if account is currently locked
  def account_locked?
    return false if locked_at.nil?
    locked_at > LOCK_DURATION.ago
  end
  
  # Reset failed attempts counter (called on successful login)
  def reset_failed_attempts!
    update_columns(failed_attempts: 0, locked_at: nil, unlock_token: nil)
  end
  
  # Generate unlock URL for email notifications
  def unlock_url
    return nil unless unlock_token.present?
    Rails.application.routes.url_helpers.unlock_account_url(token: unlock_token)
  end
  
  # Get remaining lock time in minutes
  def remaining_lock_time_in_minutes
    return 0 unless account_locked?
    remaining_seconds = (locked_at + LOCK_DURATION - Time.current).to_i
    (remaining_seconds / 60.0).ceil
  end
end
