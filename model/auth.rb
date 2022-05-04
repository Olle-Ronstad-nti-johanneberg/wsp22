require 'bcrypt'

module Auth
  # return true or false according to if the user is has the reqierd autoriztaion
  # TODO make so it updats last logging attmept and such

  #
  # Returns true or false if the user is authorized, authentication level is ignored if the user wich want to
  # get autntication is the same as the owner
  #
  # @param [Integer] owner_id The id of the user who owns the object
  # @param [Integer] req_auth_level The authentication level requierd 
  # @param [Integer] user_id The id of the user wich wish to get authentication
  # @param [String]] user_passwd the password of the user wich wish to get authentication
  #
  # @return [Boolean] if the user is authorized or not
  #
  def auth(owner_id, req_auth_level, user_id, user_passwd)
    db = load_db
    if owner_id == user_id
      user_hash = db.execute('SELECT paswd_hash FROM users WHERE id=?', owner_id)[0]
      BCrypt::Password.new(user_hash['paswd_hash']) == user_passwd
    elsif user_id.nil?
      false
    else
      user_hash = db.execute('SELECT paswd_hash, admin_level FROM users WHERE id=?', user_id)[0]
      (user_hash['admin_level'] >= req_auth_level) && BCrypt::Password.new(user_hash['paswd_hash']) == user_passwd
    end
  end

  def cookie_auth(owner_id, req_auth_level)
    if session[:user_id]
      session[:user_id] == owner_id || session[:admin_level] >= req_auth_level
    else
      false
    end
  end
end
