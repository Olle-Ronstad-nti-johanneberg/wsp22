require 'sinatra'
require 'sqlite3'
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

get '/' do
    slim :index
end

get '/account/login' do 
    slim :login
end