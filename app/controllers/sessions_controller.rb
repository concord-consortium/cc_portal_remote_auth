class SessionsController < Devise::SessionsController
  # Disable CSRF token verification, as this controller is used for remote login and logout.
  # It's not necessary, as there's no session before user signs in and we don't care about session when we log out.
  # However there's warning each time. Also, Rails can be configured to trigger an exception when CSRF token validation
  # fails, so better to handle that correctly.
  skip_before_filter :verify_authenticity_token
end
