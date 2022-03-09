require 'bcrypt'
require 'sqlite3'


#load the database and sets reasult as hash flag to true
def load_db()
    db = SQLite3::Database.new('DB/DataBase.db')
    db.results_as_hash = true
    db
end

#return true or false according to if the user is has the reqierd autoriztaion
#TODO make so it updats last logging attmept and such
def auth(owner_id,req_auth_level,user_id,user_passwd)
    return true
    db = load_db()
    if owner_id == user_id
        return db.execute("SELECT paswd_hash FROM users WHERE id=?",owner_id)[0]["id"] == BCrypt::Password.create(user_passwd)
    else
        user_hash = db.execute("SELECT paswd_hash FROM users WHERE id=?",owner_id)[0]
        return (user_hash["admin_level"] >= req_auth_level) && user_hash["paswd_hash"] == BCrypt::Password.create(user_passwd)
    end
end

#return data about the user
def get_user(id)
    return load_db().execute("SELECT user_name,first_name,last_name,admin_level FROM users WHERE id=?",id)[0]
end

#return data about the user wich is demed public, such as username and firstname 
def get_user_pub(id)
    return load_db().execute("SELECT user_name,first_name FROM users WHERE id=?",id)[0]
end

#creates the user with the specified data and returns the users id
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