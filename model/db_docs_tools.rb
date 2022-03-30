def create_doc(head,body,source)
    db = load_db()
    date = Time.new.to_s
    db.execute("INSERT INTO doc (date, head, body, source) VALUES (?,?,?,?)",
    date,
    head,
    body,
    source)
    return db.execute("SELECT id FROM doc WHERE date=? AND head=?",date, head)[0]["id"]
end