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


require_relative 'model.rb'




get '/' do
    slim :index
end

get '/account/login' do 
    slim :login
end

get '/account/new' do 
    slim :account_new
end

post 'account/new' do
    if params[:passwd] == params[:passwd_re]
        id = create_user(params[:user_name],
            params[:first_name],
            params[:last_name],
            params[:passwd])
        redirect
    else
    end

end

get '/error' do 
    slim :error