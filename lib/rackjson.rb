require 'rubygems'
require 'json'
require 'rack'
require 'mongo'
require 'time'
require 'rackjson/rack/builder'
require 'rackjson/extensions/core/array'
require 'rackjson/extensions/core/string'
require 'rackjson/errors'

module Rack::JSON

  autoload :BaseDocument, 'rackjson/base_document'
  autoload :Builder, 'rackjson/rack/builder'
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
  autoload :ObjectId, 'rackjson/extensions/bson/object_id'
  autoload :OrderedHash, 'rackjson/extensions/bson/ordered_hash'

end