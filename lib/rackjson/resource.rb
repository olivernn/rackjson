module Rack::JSON
  class Resource
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
        @collection = @db[request.collection]
        send(request.request_method.downcase, request)
      end
    end

    private

    def bypass?(request)
      @collections.include? request.collection
    end

    def connect(request)
      render "", :status => 405
    end

    def delete(request)
      if request.member_path?
        if @collection.remove({:_id => request.resource_id})
          render "{'ok': true}"
        end
      else
        render "", :status => 405
      end
    end

    def get(request)
      request.query.selector.merge!({:_id => request.resource_id}) if request.member_path?
      rows = []
      @collection.find(request.query.selector, request.query.options).each { |row| rows << Rack::JSON::Document.new(row).attributes }
      if rows.empty? && request.member_path?
        render "document not found", :status => 404
      else
        render JSON.generate(rows)
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
      document = Rack::JSON::Document.new(request.json)
      @collection.insert(document.attributes)
      render document.to_json, :status => 201
    rescue JSON::ParserError => error
      render (error.class.to_s + " :" + error.message), :status => 422
    end

    def put(request)
      document = Rack::JSON::Document.new(request.json)
      document.add_id(request.resource_id)
      @collection.save(document.attributes)
      render document.to_json
    rescue JSON::ParserError => error
      render (error.class.to_s + " :" + error.message), :status => 422
    end

    def render(body, options={})
      Rack::JSON::Response.new(body, options).to_a
    end

    def trace(request)
      render "", :status => 405
    end
  end
end