#
# Contains methods related to posts
#
module DBPostTools
  #
  # Creates a post with the given head, body, time at creation and links to docs and user who created it
  #
  # @param [String] head The head of the post
  # @param [String] body The body of the post
  # @param [Array<Integer>] doc_link_ids An array of doc ids #{intgers} which describe the docs to link to
  #
  # @return [Integer] Id of the created post
  #
  def create_post(head, body, doc_link_ids)
    db = load_db
    date = Time.new.to_s
    db.execute('INSERT INTO post (date, head, body, user)
               VALUES (?,?,?,?)',
               date,
               head,
               body,
               session[:user_id])
    id = db.last_insert_row_id
    create_post_doc_link(id, doc_link_ids)
    id
  end

  #
  # returns the data for a given post
  #
  # @param [Integer] id Id of the desierd post
  #
  # @return [Hash] A #{Hash} with the keys 'date', 'head', 'body' and 'user'
  #
  def get_post_by_id(id)
    db = load_db
    db.execute('SELECT date, head, body, user
               FROM post
               WHERE id = ?',
               id).first
  end

  #
  # Returns a #{Array} with the head and id of the docs linked to the given post
  #
  # @param [Integer] id the id of the post
  #
  # @return [Array<Hash>] An array with Hashes wich contain 'id' => doc ID and 'head' => doc Head
  #
  def get_doc_links_from_post_id(id)
    db = load_db
    db.execute('SELECT doc.id, doc.head
               FROM doc
               INNER JOIN doc_post_rel
               ON doc_post_rel.doc = doc.id
               WHERE doc_post_rel.post = ?',
               id)
  end

  #
  # Creates doc post links in the post_doc_rel tabel
  #
  # @param [Integer] id Id of the post
  # @param [Array<Integer>] doc_link_ids An array of doc ids #{intgers} which describe the docs the post is linked with
  #
  def create_post_doc_link(id, doc_link_ids)
    db = load_db
    doc_link_ids.each do |doc_id|
      db.execute('INSERT
                 INTO doc_post_rel (post, doc)
                 VALUES (?,?)',
                 id,
                 doc_id)
    end
  end

  #
  # Removes doc post links in the post_doc_rel tabel
  #
  # @param [Integer] id Id of the post
  #
  def delete_post_links(id)
    db = load_db
    db.execute('DELETE
               FROM doc_post_rel
               WHERE post = ?',
               id)
  end

  #
  # Updates the Post with specified id with the given head, body, time at update and links to docs
  #
  # @param [Integer] id Id of the post
  # @param [String] body The body of the post
  # @param [Array<Integer>] doc_link_ids An array of doc ids #[intgers] which describe the docs to link to
  #
  def update_post(id, body, head, doc_link_ids)
    db = load_db
    date = Time.new.to_s
    db.execute('UPDATE post
               SET head = ?,body = ?, date = ?
               WHERE id = ?',
               head,
               body,
               date,
               id)
    delete_post_links(id)
    create_post_doc_link(id, doc_link_ids)
  end

  def search_posts(word)
    db = load_db
    db.execute('SELECT id, head, date
               FROM post
               WHERE head LIKE ?',
               "%#{word}%")
  end
end
