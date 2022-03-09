require 'sinatra'
require 'sinatra/custom_logger'
require 'logger'
require 'slim'

p "loaded sinatra, sqlite3,,sinatra/custom_logger, logger, slim"
set :logger, Logger.new(File.open('./log', 'a'))

if ARGV.include?("d")
    require 'byebug'
    require 'sinatra/reloader'
    p "loaded bybug, sinatra/reloader"
    set :logger, Logger::DEBUG
    p "set logger to DEBUG"
else
    set :logger, Logger::WARN
    p "set logger to INFO"
end


require_relative 'terminal_color.rb'
require_relative 'model.rb'

enable :sessions

def send_err_msg(msg)
    session[:err_msg] = msg
    redirect '/error'
end


get '/' do
    slim :index
end

get '/account/login' do 
    slim :login
end

get '/account/new' do 
    slim :account_new
end

post '/account/new' do
    if params[:passwd] == params[:passwd_re]
        id = create_user(
            params[:user_name],
            params[:first_name],
            params[:last_name],
            params[:passwd])
        if id == -1
            send_err_msg("first and last name combo alredy exist")
        end
        redirect "/account/#{id}"
    else
        
        send_err_msg("passwords don't match")
    end

end

get '/account/:id/edit' do
    slim :account_edit, locals:{user:get_user(params[:id])}
end

post '/account/:id/update' do 
    if auth(params[:id],10,get_user_id(params[:auth_first_name],params[:auth_last_name]),params[:auth_paswd])
        load_db().execute("UPDATE users SET user_name = ?,first_name = ?, last_name = ? WHERE id = ?",params[:user_name],params[:first_name],params[:last_name],params[:id])
        redirect "/account/#{params[:id]}"
    else
        send_err_msg("authentication failed")
    end
end


get '/account/:id' do 
    slim :account, locals:{user:get_user_pub(params[:id])}
end

get '/error' do 
    slim :error, locals:{msg:session[:err_msg]}
    #slim :error locals:{msg:params[:msg]}
end