require 'bcrypt'
require 'sqlite3'

#creates the user with the specified data and returns the users id
def load_db()
    db = SQLite3::Database.new('DB/DataBase.db')
    db.results_as_hash = true
    db
end

def auth(owner_id,req_auth_level,user_id,user_passwd)
    return true
    db = load_db()
    if owner_id == user_id
        return db.execute("SELECT paswd_hash FROM users WHERE id=?",owner_id)[0]["id"] == BCrypt::Password.create(user_passwd)
    else
        user_hash = db.execute("SELECT paswd_hash FROM users WHERE id=?",owner_id)[0]
        return (user_hash["admin_level"] >= req_auth_level) && user_hash["paswd_hash"]BCrypt::Password.create(user_passwd)
    end
end


def get_user(id)
    return load_db().execute("SELECT user_name,first_name,last_name,admin_level FROM users WHERE id=?",id)[0]
end


def get_user_pub(id)
    return load_db().execute("SELECT user_name,first_name,last_name,admin_level FROM users WHERE id=?",id)[0]
end

def create_user(user_name, first_name, last_name, passwd)
    db = SQLite3::Database.new('DB/DataBase.db')
    if db.execute("SELECT * FROM users WHERE first_name=? AND last_name=?",first_name,last_name).empty?
        db.execute("INSERT INTO users (user_name,first_name,last_name, paswd_hash,admin_level) VALUES (?,?,?,?,?)",
        user_name,
        first_name,
        last_name,
        x = BCrypt::Password.create(passwd),
        1)
        return db.execute("SELECT id FROM users WHERE user_name=? AND paswd_hash=?",user_name, x)[0][0]
    else
        return -1
    end
end