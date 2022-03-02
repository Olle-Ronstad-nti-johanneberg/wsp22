require 'bcrypt'
require 'sqlite3'


def create_user(user_name, first_name, last_name, passwd)
    db = SQLite3::Database.new('DB/DataBase.db')
    db.execute("INSERT INTO users (user_name,first_name,last_name, paswd_hash,admin_level) VALUES (?,?,?,?,?)",
    user_name,
    first_name,
    last_name,
    BCrypt::Password.create(passwd),
    1)
end