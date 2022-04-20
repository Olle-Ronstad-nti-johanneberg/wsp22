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

enable :sessions
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
    send_err_msg('first and last name combo alredy exist') if id == -1
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
  if auth(params[:id], 10, get_user_id(params[:auth_first_name], params[:auth_last_name]), params[:auth_paswd])
    load_db.execute('UPDATE users SET user_name = ?,first_name = ?, last_name = ? WHERE id = ?',
                    params[:user_name], params[:first_name], params[:last_name], params[:id])
    redirect "/account/#{params[:id]}"
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
  slim :"doc/edit", locals: { doc: get_doc_by_id(params[:id].to_i) }
end

post '/docs/:id/update' do
  if true
    update_doc(params[:id],params[:head], params[:body], params[:source])
    redirect redirect "/docs/#{params[:id]}"
  else
    send_err_msg 'hello hackerman'
  end
end

get '/docs/search' do
  slim :"doc/index", locals:{docs:search_doc(params[:search])}
end

get '/docs/:id' do
  slim :"doc/show", locals: { doc: get_doc_by_id(params[:id].to_i) }
end
