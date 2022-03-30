require 'sqlite3'

#load the database and sets reasult as hash flag to true
def load_db()
    db = SQLite3::Database.new('DB/DataBase.db')
    db.results_as_hash = true
    db
end
