class RemoteAuthController < ApplicationController
  # verify a CC token
  def verify_cc_token
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"

    begin
      token = cookies[CCCookieAuth.cookie_name]
      raise 'non-existent token' unless token
      valid = CCCookieAuth.verify_auth_token(token,request.remote_ip)
      raise 'invalid token' unless valid
      login = token.split(CCCookieAuth.token_separator).first
      raise 'token parse error' unless login
      user = User.find_by_login(login)
      raise 'bogus user' unless user
      values = {:login => login, :first => user.first_name, :last => user.last_name}
      student = user.portal_student
      teacher = user.portal_teacher
      # values[:group] = user.group_account_class_id ? true : false
      if student
        values[:class_words] = student.clazzes.map{ |c| c.class_word }
        values[:teacher] = false
        values[:classes] = student.clazzes.map{|c|
          cohorts = c.teachers.map{|t| t.cohorts}.flatten.compact.uniq
          val = {:teacher => (c.teacher.name rescue "unknown"), :word => c.class_word, :name => c.name, :cohorts => cohorts}
          offerings = c.offerings
          offerings = offerings.select{|o| o.active && o.runnable.is_a?(ExternalActivity)}
          offerings = offerings.select{|o|
            runnable_url = o.runnable.url.gsub(/\/\s*$/,'') rescue nil
            save_path = o.runnable.save_path.gsub(/\/\s*$/,'') rescue nil
            referrer = request.referrer.gsub(/\/\s*$/,'')
            town_level_referrer = referrer.gsub(/(\?task=(?:baseline\/)?\d+)\/\d+$/) {|m| $1 }
            runnable_url == referrer || save_path == referrer || save_path == town_level_referrer
          }
          offering = offerings.first
          if offering # what do we do if somehow multiple external activities with the same url are assigned to the same class??
            learner = offering.find_or_create_learner(student)
            val[:learner] = learner.id if learner
          end
          val
        }
        values[:cohorts] = values[:classes].map{|vc| vc[:cohorts]}.flatten.compact.uniq.map{|c| c.name}
      end
      if teacher
        values[:class_words] = teacher.clazzes.map{ |c| c.class_word }
        values[:cohorts] = teacher.cohorts.map{|c| c.name }
        values[:teacher] = true
      end
      render :json => values
    rescue Exception => e
      render :text => "authentication failure: #{e.message}", :status => 403
    end
  end
end
