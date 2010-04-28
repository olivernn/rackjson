require 'rubygems'
require 'json'
require 'rack'
require 'mongo'
require 'time'

module Rack::JSON

  autoload :EndPoint, 'rackjson/end_point'
  autoload :Collection, 'rackjson/collection'
  autoload :Filter, 'rackjson/filter'
  autoload :Document, 'rackjson/document'
  autoload :JSONDocument, 'rackjson/json_document'
  autoload :JSONQuery, 'rackjson/json_query'
  autoload :MongoDocument, 'rackjson/mongo_document'
  autoload :Request, 'rackjson/request'
  autoload :Resource, 'rackjson/resource'
  autoload :Response, 'rackjson/response'

end