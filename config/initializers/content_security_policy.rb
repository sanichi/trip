# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src     :none
    policy.connect_src     :self
    policy.img_src         :self, :data
    policy.script_src      :self
    policy.style_src       :self, :unsafe_inline # redcarpet
    policy.base_uri        :self
    policy.frame_ancestors :none
    policy.form_action     :self
    policy.report_uri      "https://hou.sanichi.me/reports"
  end
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w(script-src)
  config.content_security_policy_report_only = false
end
