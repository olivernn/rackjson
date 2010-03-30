module Rack::JSON
  class Request < Rack::Request
    include Rack::Utils
    def initialize(env)
      super(env)
    end

    def collection
      self.path_info.split('/')[1]
    end

    def json
      self.body.rewind
      self.body.read
    end

    def query
      @query ||= Rack::JSON::JSONQuery.new(unescape(query_string))
    end

    def resource_id
      id_string = self.path_info.split('/').last.to_s
      begin
        Mongo::ObjectID.from_string(id_string)
      rescue Mongo::InvalidObjectID
        id_string.match(/^\d+$/) ? id_string.to_i : id_string
      end
    end
  end
end