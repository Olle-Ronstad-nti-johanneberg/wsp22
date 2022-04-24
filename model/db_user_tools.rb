require 'bcrypt'

module DBUserTools
  # return user id based on first_name and last_name
  def get_user_id(first_name, last_name)
    x = load_db.execute('SELECT id FROM users WHERE first_name=? AND last_name=?', first_name, last_name)[0]
    if x.nil?
      nil
    else
      x['id']
    end
  end

  # return data about the user
  def get_user(id)
    load_db.execute('SELECT id, user_name,first_name,last_name,admin_level FROM users WHERE id=?', id)[0]
  end

  # return data about the user wich is demed public, such as username and firstname
  def get_user_pub(id)
    load_db.execute('SELECT user_name,first_name FROM users WHERE id=?', id)[0]
  end

  # creates the user with the specified data and returns the users id
  def create_user(user_name, first_name, last_name, passwd)
    db = load_db
    if db.execute('SELECT * FROM users WHERE first_name=? AND last_name=?', first_name, last_name).empty?
      db.execute('INSERT INTO users (user_name, first_name, last_name, paswd_hash, admin_level) VALUES (?,?,?,?,?)',
                user_name,
                first_name,
                last_name,
                x = BCrypt::Password.create(passwd),
                1)
      db.execute('SELECT id FROM users WHERE user_name=? AND paswd_hash=?', user_name, x)[0]['id']
    else
      -1
    end
  end
end