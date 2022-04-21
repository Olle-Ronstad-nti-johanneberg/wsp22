def create_doc(head, body, source)
  db = load_db
  date = Time.new.to_s
  db.execute('INSERT INTO doc (date, head, body, source) VALUES (?,?,?,?)',
             date,
             head,
             body,
             source)
  db.execute('SELECT id FROM doc WHERE date=? AND head=?',
             date,
             head)[0]['id']
end

def get_doc_by_id(id)
  db = load_db
  db.execute('SELECT * FROM doc WHERE id = ?', id)[0]
end

def update_doc(id, head, body, source)
  db = load_db
  date = Time.new.to_s
  db.execute('UPDATE doc SET head = ?,body = ?, source = ?, date = ? WHERE id = ?',
             head,
             body,
             source,
             date,
             id)
end

def search_doc(word)
  db = load_db
  db.execute('SELECT id, head, date FROM doc WHERE head LIKE ?',
             "%#{word}%")
end

def get_all_docs_head_id
  db = load_db
  db.execute('SELECT id, head FROM doc')
end
