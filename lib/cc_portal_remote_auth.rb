require "cc_portal_remote_auth/engine"
require "cgi"
require "cc_cookie_auth"

module CcPortalRemoteAuth
  Devise::Strategies::Authenticatable.class_eval do
    def params_auth_hash_with_remote
      if params[:login] && params[:password]
        return { :login => params[:login], :password => params[:password] }
      end
      return params_auth_hash_without_remote
    end
    alias_method_chain :params_auth_hash, :remote
  end

  Warden::Manager.after_authentication do |user, warden, options|
    cookies = warden.cookies
    request = warden.request
    token = CCCookieAuth.make_auth_token(user.login, request.remote_ip)
    cookies[CCCookieAuth.cookie_name.to_sym] = {:value => token, :domain => cookie_domain(request) }
  end

  Warden::Manager.before_logout do |user, warden, options|
    cookies = warden.cookies
    if cookies.kind_of? ActionDispatch::Cookies::CookieJar
      cookies.delete(CCCookieAuth.cookie_name.to_sym, {:domain => cookie_domain(warden.request)})
    else
      cookies.delete CCCookieAuth.cookie_name.to_sym
    end
  end

  def self.cookie_domain(request)
    # use wildcard domain (last two parts ".concord.org") for this cookie
    domain = request.host
    domain = '.concord.org' if domain =~ /\.concord\.org$/

    return domain
  end
end
