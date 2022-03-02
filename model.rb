require 'bcrypt'
require 'sqlite3'

#creates the user with the specified data and returns the users id
def create_user(user_name, first_name, last_name, passwd)
    db = SQLite3::Database.new('DB/DataBase.db')
    db.execute("INSERT INTO users (user_name,first_name,last_name, paswd_hash,admin_level) VALUES (?,?,?,?,?)",
    user_name,
    first_name,
    last_name,
    x = BCrypt::Password.create(passwd),
    1)
    db.execute("SELECT id FROM users WHERE user_name=? AND paswd_hash=?",user_name, x)[0][0]
end