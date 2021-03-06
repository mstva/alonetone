# frozen_string_literal: true

# Implements controller helper methods to deal with authorization.
module Authorization
  def admin?
    logged_in? && current_user.admin?
  end

  def moderator?
    logged_in? && (current_user.moderator? || current_user.admin?)
  end

  def require_login
    force_login unless logged_in? && authorized?
  end

  def admin_only
    force_admin_login unless admin?
  end

  def moderator_only
    force_mod_login unless moderator?
  end

  def force_login
    store_location
    redirect_to login_path, alert: "Whups, you need to login for that!"
  end

  def force_mod_login
    store_location
    redirect_to login_path, alert: "Super special secret area. Alonetone Elite Only."
  end

  def force_admin_login
    store_location
    redirect_to login_path, alert: "What do you think you’re doing?! We're calling your mother..."
  end
end
