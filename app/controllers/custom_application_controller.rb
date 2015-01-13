class CustomApplicationController < ApplicationController
  # This controller isn't intended to do anything, except for add some routes to the sensitive path function in application controller.
  # We're doing it here because we know that ApplicationController will have been set up by the time this is initialized.

  Rails.logger.warn("Overriding session_sensitive_path")
  ::ApplicationController.class_eval do
    private
    alias_method :parent_session_sensitive_path, :session_sensitive_path
    def session_sensitive_path
      path = request.env['PATH_INFO']
      return (path =~ /remote_login|remote_logout|verify_cc_token/i) || parent_session_sensitive_path
    end
  end
end
