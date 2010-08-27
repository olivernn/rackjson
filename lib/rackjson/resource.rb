module Rack::JSON
  class Resource
    include Rack::JSON::EndPoint
    HTTP_METHODS = [:get, :post, :put, :delete]

    def initialize(app, options)
      @app = app
      @collections = options[:collections]
      @db = options[:db]
      @methods = options[:only] || HTTP_METHODS - (options[:except] || [])
    end

    def call(env)
      request = Rack::JSON::Request.new(env)
      if bypass? request
        @app.call(env)
      elsif method_not_allowed? request
        render "", :status => 405
      else
        @collection = Rack::JSON::Collection.new(@db[request.collection])
        send(request.request_method.downcase, request)
      end
    end

    private

    def create(request)
      document = Rack::JSON::Document.create(request.json)
      @collection.save(document)
      render document, :status => 201
    end

    def delete(request)
      if request.field_path?
        @collection.delete_field(request.query.selector, request.fields)
        render "", :status => 204
      elsif request.member_path?
        @collection.delete(request.query.selector)
        render "", :status => 204
      else
        render "", :status => 405
      end
    end

    [:get, :head].each do |method|
      define_method method do |request|
        begin
          send("get_#{request.path_type}", request, method)
        rescue Rack::JSON::Request::UnrecognisedPathTypeError => error
          bad_request error
        end
      end
    end

    def get_collection(request, method)
      render @collection.find(request.query.selector, request.query.options)
    end

    def get_field(request, method)
      field = @collection.find_field(request.query.selector, request.fields, request.query.options)
      if field
        render field, :head => (method == :head)
      else
        render "field not found", :status => 404, :head => (method == :head)
      end
    end

    def get_member(request, method)
      document = @collection.find_one(request.query.selector, request.query.options)
      if document
        render document, :head => (method == :head)
      else
        render "document not found", :status => 404, :head => (method == :head)
      end
    end

    def options(request)
      if request.collection_path?
        headers = { "Allow" => "GET, POST" }
      elsif request.member_path?
        headers = { "Allow" => "GET, PUT, DELETE" }
      end
      render "", :headers => headers
    end

    def post(request)
      if request.collection_path?
        create(request)
      elsif request.modifier_path?
        @collection.exists?(request.resource_id) ? modify(request) : render("document not found", :status => 404)
      end
    rescue JSON::ParserError => error
      invalid_json error
    end

    def put(request)
      if request.field_path?
        @collection.exists?(request.resource_id) ? update_field(request) : render("document not found", :status => 404)
      else
        @collection.exists?(request.resource_id) ? update(request) : upsert(request)
      end
    rescue JSON::ParserError => error
      invalid_json error
    end

    def modify(request)
      @collection.send(request.modifier[1..-1], request.query.selector, request.fields, request.modifier_value)
      render "OK", :status => 200
    end

    def update(request)
      document = Rack::JSON::Document.create(request.json)
      document.set_id(request.resource_id)
      if @collection.update(request.resource_id, document, request.query.selector)
        render document, :status => 200
      else
        render "document not found", :status => 404
      end
    end

    def update_field(request)
      @collection.update_field(request.query.selector, request.fields, request.modifier_value)
      render "OK", :status => 200
    end

    def upsert(request)
      document = Rack::JSON::Document.create(request.json)
      document.set_id(request.resource_id)
      @collection.save(document)
      render document, :status => 201
    end

  end
end