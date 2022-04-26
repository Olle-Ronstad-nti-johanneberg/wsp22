# frozen_string_literal: true

require 'bcrypt'

module DBUserTools
  #
  # return user id based on first_name and last_name
  #
  # @param [String] first_name First name of user
  # @param [String] last_name Last name of user
  #
  # @return [Integer] Id of user
  #
  def get_user_id(first_name, last_name)
    x = load_db.execute('SELECT id
                        FROM users
                        WHERE first_name=? AND last_name=?',
                        first_name,
                        last_name)[0]
    if x.nil?
      nil
    else
      x['id']
    end
  end

  # return data about the user

  #
  # Returns data about the user
  #
  # @param [Integer] id Id of the user
  #
  # @return [Hash] A hash with the keys 'user_name', 'first_name', 'last_name' and 'admin_level'
  #
  def get_user(id)
    load_db.execute('SELECT id, user_name, first_name, last_name, admin_level
                    FROM users
                    WHERE id=?',
                    id)[0]
  end

  #
  # Return data about the user wich is demed public, such as username and firstname
  #
  # @param [Integer] id The id of the user
  #
  # @return [Hash] A hash with the keys 'user_name' and 'first_name'
  #
  def get_user_pub(id)
    load_db.execute('SELECT user_name,first_name FROM users WHERE id=?', id)[0]
  end

  #
  # Creates the user with the specified data and returns the users id
  #
  # @param [String] user_name User name
  # @param [String] first_name First name
  # @param [String] last_name Last name
  # @param [String] passwd plain text password
  # @note password is digested
  #
  # @return [Integer] Id of user, -1 if first_name last_name combo alredy exist
  #
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

  #
  # Returns user_name of the given id
  #
  # @param [Integer] id Id of the user
  #
  # @return [String] user_name of the user
  #
  def get_user_name(id)
    load_db.execute('SELECT user_name
                    FROM users
                    WHERE id=?', id)[0]['user_name']
  end

  #
  # Uppdates the user information returns 1 if sucessful and -1 if user_first_name/user_last_ exist
  #
  # @param [Integer] id id of the user to update
  # @param [String] user_name New user_name
  # @param [String] first_name New user_fisrt_name
  # @param [String] last_name New user_last_name
  #
  # @return [Integer] Returns 1 if sucessful and -1 if user_first_name/user_last_ exist
  #
  def update_user(id, user_name, first_name, last_name)
    db = load_db
    if allow_first_last_name_change?(id, first_name, last_name)
      db.execute('UPDATE users
                 SET user_name = ?,first_name = ?, last_name = ?
                 WHERE id = ?',
                 user_name,
                 first_name,
                 last_name,
                 id)
      1
    else
      -1
    end
  end

  #
  # Updates users password
  #
  # @param [Integer] id Id of the user
  # @param [String] new_password The new password to set
  #
  def update_paswd(id, new_password)
    load_db.execute('UPDATE users
                    SET paswd_hash = ?
                    WHERE id = ?',
                    BCrypt::Password.create(new_password),
                    id)
  end

  private

  #
  # Returns true or false acording to if a first name last name combination all ready exists ignoring if user alredy has the last name and first name 
  #
  # @param [Integer] id Id of user
  # @param [<Type>] first_name New first name
  # @param [<Type>] last_name New last name
  #
  # @return [Boolean] se description
  #
  def allow_first_last_name_change?(id, first_name, last_name)
    db = load_db
    user_names = db.execute('SELECT first_name, last_name
                            FROM users
                            WHERE id=?',
                            id).first
    if user_names['first_name'] == first_name && user_names['last_name'] == last_name
      true
    else
      db.execute('SELECT *
                 FROM users
                 WHERE first_name=? AND last_name=?',
                 first_name,
                 last_name).empty?
    end
  end
end
