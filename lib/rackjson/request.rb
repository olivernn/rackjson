module Rack::JSON
  class Request < Rack::Request
    include Rack::Utils

    attr_reader :env

    def initialize(env)
      @env = env
      super(env)
    end

    def add_query_param(param)
      self.query_string << param
    end

    def collection
      self.path_info.split('/')[1] || ""
    end

    def collection_path?
      self.path_info.match /^\/\w+$/
    end

    def member_path?
      self.path_info.match /^\/\w+\/\w+$/
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

    def session
      @env['rack.session']
    end

    def set_body json
      @env['rack.input'] = StringIO.new(json)
      @env['rack.input'].rewind
    end
  end
end