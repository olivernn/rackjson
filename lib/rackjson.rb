class Hash
  def symbolize_keys
    inject({}) do |options, (key, value)|
      options[(key.to_sym rescue key) || key] = value
      options
    end
  end

  def symbolize_keys!
    self.replace(self.symbolize_keys)
  end

  def recursive_symbolize_keys!
    symbolize_keys!
    # symbolize each hash in .values
    values.each{|h| h.recursive_symbolize_keys! if h.is_a?(Hash) }
    # symbolize each hash inside an array in .values
    values.select{|v| v.is_a?(Array) }.flatten.each{|h| h.recursive_symbolize_keys! if h.is_a?(Hash) }
    self
  end
end

require 'rubygems'
require 'json'
require 'rack'
require 'mongo'
require 'time'

module Rack::JSON

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