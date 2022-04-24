#
# Contains methods related to docs
#
module DBDocsTools
  #
  # Creates a doc with the given head, body and source. Automatically sets date to the time of creation
  #
  # @param [String] head The head of the doc
  # @param [String] body The body of the doc
  # @param [String] source The source of the doc (url)
  #
  # @return [Integer] Id of the created doc
  #
  def create_doc(head, body, source)
    db = load_db
    date = Time.new.to_s
    db.execute('INSERT
               INTO doc (date, head, body, source)
               VALUES (?,?,?,?)',
               date,
               head,
               body,
               source)
    db.execute('SELECT id
               FROM doc
               WHERE date=? AND head=?',
               date,
               head)[0]['id']
  end

  #
  # Returns the doc with the given id
  #
  # @param [Integer] id The id of the specified doc
  #
  # @return [Hash] An #{Hash} with the keys 'id', 'body', 'date' and 'source'
  #
  def get_doc_by_id(id)
    db = load_db
    db.execute('SELECT *
               FROM doc
               WHERE id = ?',
               id)[0]
  end

  #
  # Updates the doc with the given id with the given values head, body and source. Automatically sets the date to the time of the update
  #
  # @param [Integer] id The id of the specified doc
  # @param [String] head The head of the doc
  # @param [String] body The body of the doc
  # @param [String] source The source of the doc (url)
  #
  def update_doc(id, head, body, source)
    db = load_db
    date = Time.new.to_s
    db.execute('UPDATE doc
               SET head = ?,body = ?, source = ?, date = ?
               WHERE id = ?',
               head,
               body,
               source,
               date,
               id)
  end

  #
  # Returns an #{Array} with docs whose head contain the word
  #
  # @param [String] word The string wich head must contain
  #
  # @return [Array<Hash>] An #{Array} with #{Hash} with the keys ´id´, 'head' and 'date'
  #
  def search_doc(word)
    db = load_db
    db.execute('SELECT id, head, date
               FROM doc
               WHERE head LIKE ?',
               "%#{word}%")
  end

  #
  # Returns an #{Array} with #{Hash} containing all doc ids and heads
  #
  # @return [Array<Hash>] An #{Array} with #{Hash} with the keys ´id´ and 'head'
  #
  def get_all_docs_head_id
    db = load_db
    db.execute('SELECT id, head
               FROM doc')
  end
end
