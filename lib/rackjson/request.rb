module Rack::JSON
  class Request < Rack::Request

    include Rack::Utils

    def add_query_param(param)
      self.query_string << param
    end

    def collection
      self.path_info.split('/')[1] || ""
    end

    def collection_path?
      self.path_info.match /^\/[\w-]+$/
    end

    def field
      path_info.split('/')[3] || ""
    end

    def fields
      path_info.split('/').slice(3..-1).reject { |f| f.match(/(_increment|_decrement|_push|_pull|_push_all|_pull_all|_add_to_set)/)} || []
    end

    def field_path?
      path_info.match(/^\/[\w-]+\/[\w-]+\/[\w-]+(\/[\w-]+)*$/) && !modifier_path?
    end

    def member_path?
      self.path_info.match /^\/[\w-]+\/[\w-]+$/
    end

    def modifier
      modifier_path? ? path_info.split('/').last : nil
    end

    def modifier_path?
      path_info.match /^\/[\w-]+\/[\w-]+\/[\w-]+(\/[\w-]+)*\/(_increment|_decrement|_push|_pull|_push_all|_pull_all|_add_to_set)$/
    end

    def path_type
      if member_path?
        :member
      elsif field_path?
        :field
      elsif collection_path?
        :collection
      else
        raise Rack::JSON::UnrecognisedPathTypeError
      end
    end

    def payload
      if content_type == 'application/json'
        JSON.parse(raw_body)
      elsif raw_body.empty?
        nil
      else
        raw_body.numeric? ? raw_body.to_number : raw_body
      end
    end

    def property
      property = path_info.split('/')[4]
      if property
        property.match(/^\d+$/)? property.to_i : property
      else
        nil
      end
    end

    def json
      raw_body
    end

    def query
      @query ||= Rack::JSON::JSONQuery.new(unescape(query_string), :resource_id => resource_id)
    end

    def raw_body
      self.body.rewind
      self.body.read
    end

    def resource_id
      unless collection_path?
        id_string = self.path_info.split('/')[2].to_s
        begin
          BSON::ObjectId.from_string(id_string)
        rescue BSON::InvalidObjectId
          id_string.match(/^\d+$/) ? id_string.to_i : id_string
        end
      end
    end

    def set_body json
      @env['rack.input'] = StringIO.new(json)
      @env['rack.input'].rewind
    end
  end
end