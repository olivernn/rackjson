module Rack::JSON
  class Response

    class Rack::JSON::Response::BodyFormatError < ArgumentError ; end

    attr_reader :status, :headers, :body

    def initialize(body, options={})
      @status = options[:status] || 200
      @head = options[:head] || false
      @headers = options[:headers] || {}
      parse_body(body)
      set_headers
      head_response if @head
    end

    def to_a
      [status, headers, [body]]
    end

    private

    def head_response
      @body = ""
    end

    def parse_body(body)
      if body.is_a?(Rack::JSON::Document) || body.is_a?(Array)
        @body = body.to_json
        @headers["Content-Type"] = "application/json"
      elsif body.is_a? String
        @body = body
        @headers["Content-Type"] = "text/plain"
      else
        raise Rack::JSON::Response::BodyFormatError
      end
    end

    def set_headers
      @headers["Content-Length"] = body.length.to_s
    end
  end
end