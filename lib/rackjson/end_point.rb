module Rack::JSON
  module EndPoint

    private

    def bypass? request
      request.collection.empty? || !(@collections.include? request.collection.to_sym)
    end

    def bypass_path? request
      bypass? request
    end

    def bypass_method? request
      !@methods.include?(request.request_method.downcase.to_sym)
    end

    def invalid_json error
      render (error.class.to_s + " :" + error.message), :status => 422
    end

    def render body, options={}
      Rack::JSON::Response.new(body, options).to_a
    end
  end
end