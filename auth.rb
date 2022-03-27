require 'bcrypt'
require 'sqlite3'

#return true or false according to if the user is has the reqierd autoriztaion
#TODO make so it updats last logging attmept and such
def auth(owner_id,req_auth_level,user_id,user_passwd)
    return true
    db = load_db()
    if owner_id == user_id
        user_hash db.execute("SELECT paswd_hash FROM users WHERE id=?",owner_id)[0]["id"]
        return BCrypt::passwd.new(user_hash["paswd_hash"]) == user_passwd
    else
        user_hash = db.execute("SELECT paswd_hash FROM users WHERE id=?",owner_id)[0]
        return (user_hash["admin_level"] >= req_auth_level) && BCrypt::passwd.new(user_hash["paswd_hash"]) == user_passwd
    end
end


#return true or false according to if the user is has the reqierd autoriztaion
#TODO make sure the cookie in't to old
def cookie_auth(owner_id,req_auth_level,session)
    return true
    if owner_id == session[:user_id]
        return true
    elsif session[:admin_level] >= req_auth_level
        return true
    else
        return false
    end
end
