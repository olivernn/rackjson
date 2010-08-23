module Rack::JSON
  module EndPoint

    private

    def bad_request error
      error_response error, 400
    end

    def bypass? request
      request.collection.empty? || !(@collections.include? request.collection.to_sym)
    end

    def bypass_path? request
      bypass? request
    end

    def bypass_method? request
      !@methods.include?(request.request_method.downcase.to_sym)
    end

    def error_response error, status_code
      render (error.class.to_s + " :" + error.message), :status => status_code
    end

    def invalid_json error
      error_response error, 422
    end

    def method_not_allowed? request
      bypass_method? request
    end

    def render body, options={}
      Rack::JSON::Response.new(body, options).to_a
    end
  end
end