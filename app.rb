require 'sinatra'

get '/' do
  "Hello World\n"
end

post '/' do
  require 'pp'
  PP.pp request
  "POST\n"
end
