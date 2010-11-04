require 'rubygems'
require 'rack'
require 'rackjson'

expose_resource :collections => [:notes], :db => Mongo::Connection.new.db("testing")

run lambda { |env| 
  [404, {'Content-Length' => '9', 'Content-Type' => 'text/plain'}, "Not Found"]
}