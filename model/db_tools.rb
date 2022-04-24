require 'sqlite3'
#
# A module with basic SQLite 3 database methods
#
module DBTools
  #
  # returns an SQLite3::Database object with the result as hash flag set to true
  #
  # @return [SQLite3::Database] The SQLite3 Database object
  #
  def load_db
    db = SQLite3::Database.new('DB/DataBase.db')
    db.results_as_hash = true
    db
  end
end
