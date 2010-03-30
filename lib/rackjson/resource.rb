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

    def delete(request)
      if @collection.remove({:_id => request.resource_id})
        [
          200,
          {"Content-Length" => "11", "Content-Type" => "application/json"},
          "{'ok':true}"
        ]
      end
    end

    def get(request)
      rows = []
      @collection.find(request.query.selector, request.query.options).each { |row| rows << Rack::JSON::Document.new(row).attributes }
      [
        200, 
        {"Content-Length" => JSON.generate(rows).length.to_s, "Content-Type" => "application/json"},
        JSON.generate(rows)
      ]
    end

    def post(request)
      document = Rack::JSON::Document.new(request.json)
      @collection.insert(document.attributes)
      [ 
        201, 
        {"Content-Length" => document.content_length, "Content-Type" => "application/json"}, 
        document.to_json
      ]
    rescue JSON::ParserError => error
      unprocessable_entity error
    end

    def put(request)
      document = Rack::JSON::Document.new(request.json)
      document.add_id(request.resource_id)
      @collection.save(document.attributes)
      [
        200,
        {"Content-Length" => document.content_length, "Content-Type" => "application/json"},
        document.to_json
      ]
    rescue JSON::ParserError => error
      unprocessable_entity error
    end

    def unprocessable_entity(error)
      response = error.class.to_s + " :" + error.message
      [
        422,
        {"Content-Length" => response.length.to_s, "Content-Type" => "text/plain"},
        response
      ]
    end

  end
end