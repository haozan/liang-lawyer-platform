# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

# IMPORTANT: Allow ActiveStorage files to be embedded in iframes
# This fixes PDF preview "blocked" errors in Clacky environment
Rails.application.config.action_dispatch.default_headers.delete('X-Frame-Options')

# Configure Content-Security-Policy to allow PDF preview in new tabs
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data, :blob
    policy.object_src  :self
    policy.script_src  :self, :https, :unsafe_inline
    policy.style_src   :self, :https, :unsafe_inline
    policy.frame_ancestors :self, :https
    policy.connect_src :self, :https, "wss://#{ENV['CLACKY_PREVIEW_DOMAIN_BASE']}", "ws://#{ENV['CLACKY_PREVIEW_DOMAIN_BASE']}"
  end

  # Generate session nonces for permitted importmap, inline scripts, and inline styles.
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w(script-src style-src)

  # Report violations without enforcing the policy.
  # config.content_security_policy_report_only = true
end
