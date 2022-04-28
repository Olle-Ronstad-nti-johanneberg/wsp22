require 'sinatra'
require 'sinatra/custom_logger'
require 'logger'
require 'slim'

p 'loaded sinatra, sqlite3,,sinatra/custom_logger, logger, slim'
set :logger, Logger.new(File.open('./log', 'a'))

# if "d" is given as an arugment at program start
# this loads things that may be used for debugging
if ARGV.include?('d')
  require 'byebug'
  require 'sinatra/reloader'
  p 'loaded bybug, sinatra/reloader'
  set :logger, Logger::DEBUG
  p 'set logger to DEBUG'
else
  set :logger, Logger::WARN
  p 'set logger to WARN'
end

require_relative 'model/terminal_color'
require_relative 'model/db_tools'
require_relative 'model/auth'
require_relative 'model/db_user_tools'
require_relative 'model/db_docs_tools'
require_relative 'model/db_posts_tools'

CREATE_DOC_AUTH = 1
EDIT_ACOUNT_AUTH = 10
EDIT_DOC_AUTH = 2
CREATE_POST_AUTH = 0
EDIT_POST_AUTH = 5

enable :sessions

include Auth, DBDocsTools, DBPostTools, DBTools, DBUserTools

#
# Redirects to /error and displays the mesage in user session[:err_msg]
#
# @param [String] msg message to display
#
def send_err_msg(msg)
  session[:err_msg] = msg
  redirect '/error'
end

#
# Displays error page
#
get '/error' do
  slim :error, locals: { msg: session[:err_msg] }
  # slim :error locals:{msg:params[:msg]}
end

# account realated routs goes here

#
# Ends the session and redirects the user to "/"
#
get '/logout' do
  session.clear
  redirect '/'
end

#
# Displays home page
#
get '/' do
  slim :index
end

#
# Displays account login page
#
get '/account/login' do
  slim :login
end

#
# Logs the user in with the help of passed data, if the user is not found
# or the password is incorect it redirects to /error and displays an error message.
# If login is succelsful redirect the user to "/account/user_id" and set session
# :user_name :user_id and :admin_level
#
# @param [String] :first_name The first name of the user attempting to log in
# @param [String] :last_name The last name of the user attempting to log in
# @param [String] :passwd The pass world of the user attempting to log in
#
post '/account/login' do
  user_id = get_user_id(params[:first_name], params[:last_name])
  send_err_msg('password or user credentials are wrong') if user_id.nil?
  if auth(user_id, 15, user_id, params[:passwd])
    user = get_user(user_id)
    session[:user_id] = user_id
    session[:user_name] = user['user_name']
    session[:admin_level] = user['admin_level']
    redirect("/account/#{user_id}")
  else
    send_err_msg('password or user credentials are wrong')
  end
end

#
# Displays account new page
#
get '/account/new' do
  slim :"account/new"
end

#
# Creataes an account, throws an error if first_name and last_name combination alredy exist
# or passwd and passwd_re don't match
#
# @param [String] :user_name
# @param [String] :first_name
# @param [String] :last_name
# @param [String] :passwd
# @param [String] :passwd_re
#
post '/account/new' do
  if params[:passwd] == params[:passwd_re]
    id = create_user(
      params[:user_name],
      params[:first_name],
      params[:last_name],
      params[:passwd]
    )
    send_err_msg('first and last name combination alredy exist') if id == -1
    redirect "/account/#{id}"
  else

    send_err_msg("passwords don't match")
  end
end

#
# Displays account edit page
#
# @param [Integer] :id Id of the user
#
get '/account/:id/edit' do
  slim :"account/edit", locals: { user: get_user(params[:id]) }
end

#
# Updats the user with the with the given information and redirects to "/account/:id".
# Throws an error if first name and last name combination is not uniqe
#
# @param [Integer] :id id of the post
# @param [String] :user_name The new user_name
# @param [String] :user_first_name The new user_first_name
# @param [String] :user_last_name The new user_last_name
# @param [String] :paswd The new user pass world, if :paswd = "" curent pass word is not changed
# @param [String] :auth_first_name The one authecating the changes first name
# @param [String] :auth_last_name The one authecating the changes last name
# @param [String] :auth_paswd_name The one authecating the changes pass word
#
post '/account/:id/update' do
  p params
  if auth(params[:id], EDIT_ACOUNT_AUTH, get_user_id(params[:auth_first_name], params[:auth_last_name]), params[:auth_paswd])
    sucsess = update_user(params[:id], params[:user_name], params[:first_name], params[:last_name])
    if sucsess == 1
      update_paswd(params[:id],params[:paswd]) unless params[:paswd] == ''
      redirect "/account/#{params[:id]}"
    else
      send_err_msg('first and last name combination alredy exist')
    end
  else
    send_err_msg('authentication failed')
  end
end

#
# Displays account page
#
# @param [Integer] :id Id of the user
#
get '/account/:id' do
  slim :"account/show", locals: { user: get_user(params[:id]),
                                  user_id: session[:user_id],
                                  posts: get_users_posts(params[:id]) }
end

#
# Displays docs new page
#
get '/docs/new' do
  if !session[:user_id].nil?
    slim :"doc/new"
  else
    send_err_msg 'please login to create docs'
  end
end

#
# Create doc with the given information, throws an error if user is not authorized.
# Redirect user to /docs/(id of the newly created doc)
#
# @param [String] :head The head of the doc
# @param [String] :body The body of the doc
# @param [String] :head The source of the doc
#
post '/docs/new' do
  if cookie_auth(nil,CREATE_DOC_AUTH)
    id = create_doc(params[:head], params[:body], params[:source])
    redirect "/docs/#{id}"
  else
    send_err_msg 'hello hackerman'
  end
end

#
# Displays account docs page
#
# @param [Integer] :id Id of the doc
#
get '/docs/:id/edit' do
  slim :"doc/edit", locals: { doc: get_doc_by_id(params[:id].to_i)}
end

#
# Updats the doc with the with the given information
#
# @param [Integer] :id id of the doc
# @param [String] :head The new head
# @param [String] :body The new body
# @param [String] :source The new Source
#
post '/docs/:id/update' do
  if cookie_auth(nil, EDIT_DOC_AUTH)
    update_doc(params[:id],params[:head], params[:body], params[:source])
    redirect "/docs/#{params[:id]}"
  else
    send_err_msg 'missing the requierd auth'
  end
end

#
# Displays all docs wich heads match the search word
#
# @param [String] :search The search word to match docs heads with
#
get '/docs/search' do
  slim :"doc/index", locals: {docs: search_doc(params[:search]) }
end

#
# Displays doc page
#
# @param [Integer] :id Id of the doc
#
get '/docs/:id' do
  slim :"doc/show", locals: { doc: get_doc_by_id(params[:id].to_i) }
end

# posts routes goes here

#
# Displays posts new page if session isn't nil esle it redirects to
# /error with message 'please login to create posts'
#
get '/posts/new' do
  if !session[:user_id].nil?
    slim :"posts/new", locals: { all_docs: get_all_docs_head_id }
  else
    send_err_msg 'please login to create posts'
  end
end

#
# Creates a new post with the with the given information
#
# @param [String] :head The new head
# @param [String] :body The new body
# @param [String] :doc_n doc to link to posts
#
post '/posts/new' do
  tmp_doc = params.select do |key, value|
    key[0, 4] == 'doc_' && value == 'on'
  end
  doc_ids = tmp_doc.to_a.map do |doc|
    doc[0][4..-1].to_i
  end
  id = create_post(params['head'], params['body'], doc_ids)
  redirect "/posts/#{id}"
end

#
# Displays post edit page
#
# @param [Integer] :id Id of the post
#
get '/posts/:id/edit' do
  slim :"posts/edit", locals: { all_docs: get_all_docs_head_id,
                                post: get_post_by_id(params[:id]),
                                doc_links: get_doc_links_from_post_id(params[:id]) }
end

#
# Updats the post with the with the given information
#
# @param [Integer] :id id of the post
# @param [String] :head The new head
# @param [String] :body The new body
# @param [String] :doc_n doc to link to posts
#
post '/posts/:id/update' do
  tmp_doc = params.select do |key, value|
    key[0, 4] == 'doc_' && value == 'on'
  end
  doc_ids = tmp_doc.to_a.map do |doc|
    doc[0][4..-1].to_i
  end
  update_post(params[:id], params['body'], params['head'], doc_ids)
  redirect "/posts/#{params[:id]}"
end

#
# Displays all post wich heads match the search word
#
# @param [String] :search The search word to match post heads with
#
get '/posts/search' do
  slim :"posts/index", locals: { posts: search_posts(params[:search]) }
end

#
# Displays post page
#
# @param [Integer] :id Id of the post
#
get '/posts/:id' do
  post = get_post_by_id(params[:id])
  doc_links = get_doc_links_from_post_id(params[:id])
  slim :"posts/show", locals: { post: post, doc_links: doc_links }
end
