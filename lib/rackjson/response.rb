module Rack::JSON
  class Response
    def initialize(body, options={})
      @status = options[:status] || 200
      @body = body
      @head = options[:head] || false
      @headers = options[:headers] || {}
      set_headers
      head_response if @head
    end

    def to_a
      [@status, @headers, [@body]]
    end

    private

    def head_response
      @body = ""
    end

    def set_headers
      @headers["Content-Length"] = @body.length.to_s
      begin
        JSON.parse(@body)
        @headers["Content-Type"] = "application/json"
      rescue JSON::ParserError => error
        # the response will only ever be either json or plain text
        @headers["Content-Type"] = "text/plain"
      end
    end
  end
end