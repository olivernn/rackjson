module Rack::JSON
  class Response

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
      @body = JSON.generate(body)
      @headers["Content-Type"] = "application/json"
    rescue JSON::GeneratorError
      @body = body
      @headers["Content-Type"] = "text/plain"
    end

    def set_headers
      @headers["Content-Length"] = body.length.to_s
    end
  end
end