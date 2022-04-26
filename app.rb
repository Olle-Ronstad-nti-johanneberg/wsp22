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

enable :sessions

include Auth, DBDocsTools, DBPostTools, DBTools, DBUserTools

# takes an argument(msg) and displays it to the user
def send_err_msg(msg)
  session[:err_msg] = msg
  redirect '/error'
end

get '/error' do
  slim :error, locals: { msg: session[:err_msg] }
  # slim :error locals:{msg:params[:msg]}
end

# account realated routs goes here

# ends the session and redirects the user to "/"
get '/logout' do
  session.clear
  redirect '/'
end

# homepage
get '/' do
  slim :index
end

# loginpage
get '/account/login' do
  slim :login
end

# logs the user in with the help of passed data, if the user is not found
# or the password is incorect an error mesage is displayed
# if login is succelsful redirect the user to "/account/user_id"
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

# create account page
get '/account/new' do
  slim :"account/new"
end

# creataes an account, if first_name and last_name combination alredy exist
# show an error
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

# account edit page
get '/account/:id/edit' do
  slim :"account/edit", locals: { user: get_user(params[:id]) }
end

# edits the account
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

# shows an account
get '/account/:id' do
  slim :"account/show", locals: { user: get_user(params[:id]), user_id:session[:user_id]}
end

# create docs page
get '/docs/new' do
  if !session[:user_id].nil?
    slim :"doc/new"
  else
    send_err_msg 'please login to create docs'
  end
end

# create doc
post '/docs/new' do
  if !session[:user_id].nil?
    id = create_doc(params[:head], params[:body], params[:source])
    redirect "/docs/#{id}"
  else
    send_err_msg 'hello hackerman'
  end
end

get '/docs/:id/edit' do
  slim :"doc/edit", locals: { doc: get_doc_by_id(params[:id].to_i)}
end

post '/docs/:id/update' do
  if cookie_auth(nil, EDIT_DOC_AUTH)
    update_doc(params[:id],params[:head], params[:body], params[:source])
    redirect "/docs/#{params[:id]}"
  else
    send_err_msg 'missing the requierd auth'
  end
end

get '/docs/search' do
  slim :"doc/index", locals:{docs:search_doc(params[:search])}
end

get '/docs/:id' do
  slim :"doc/show", locals: { doc: get_doc_by_id(params[:id].to_i), show_edit: cookie_auth(nil, EDIT_DOC_AUTH)}
end

get '/posts/new' do
  if !session[:user_id].nil?
    slim :"posts/new", locals: { all_docs: get_all_docs_head_id }
  else
    send_err_msg 'please login to create posts'
  end
end

# posts routes goes here
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

get '/posts/:id/edit' do
  slim :"posts/edit", locals: { all_docs: get_all_docs_head_id,
                                post: get_post_by_id(params[:id]),
                                doc_links: get_doc_links_from_post_id(params[:id]) }
end

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

get '/posts/search' do
  slim :"posts/index", locals: { posts: search_posts(params[:search]) }
end

get '/posts/:id' do
  post = get_post_by_id(params[:id])
  doc_links = get_doc_links_from_post_id(params[:id])
  slim :"posts/show", locals: { post: post, doc_links: doc_links }
end
