module Rack::JSON
  class Resource
    include Rack::JSON::EndPoint
    METHODS_NOT_ALLOWED = [:trace, :connect]

    def initialize(app, options)
      @app = app
      @collections = options[:collections]
      @db = options[:db]
    end

    def call(env)
      request = Rack::JSON::Request.new(env)
      if bypass? request
        @app.call(env)
      else
        @collection = Rack::JSON::Collection.new(@db[request.collection])
        send(request.request_method.downcase, request)
      end
    end

    private

    def delete(request)
      if request.member_path?
        if @collection.delete({:_id => request.resource_id})
          render "{'ok': true}"
        end
      else
        render "", :status => 405
      end
    end

    [:get, :head].each do |method|
      define_method method do |request|
        request.member_path? ? get_member(request, method) : get_collection(request, method)
      end
    end

    def get_member(request, method)
      request.query.selector.merge!({:_id => request.resource_id})
      document = @collection.find_one(request.query.selector, request.query.options)
      if document
        render document, :head => (method == :head)
      else
        render "document not found", :status => 404, :head => (method == :head)
      end
    end

    def get_collection(request, method)
      render @collection.find(request.query.selector, request.query.options)
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
      document = Rack::JSON::Document.create(request.json)
      @collection.save(document)
      render document, :status => 201
    rescue JSON::ParserError => error
      invalid_json error
    end

    def put(request)
      @collection.exists?(request.resource_id) ? update(request) : upsert(request)
    rescue JSON::ParserError => error
      invalid_json error
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

    def upsert(request)
      document = Rack::JSON::Document.create(request.json)
      document.set_id(request.resource_id)
      @collection.save(document)
      render document, :status => 201
    end

    METHODS_NOT_ALLOWED.each do |method|
      define_method method do |request|
        render "", :status => 405
      end
    end
  end
end