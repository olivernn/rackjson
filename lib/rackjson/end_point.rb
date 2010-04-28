module Rack::JSON
  module EndPoint
    def bypass? request
      request.collection.empty? || !(@collections.include? request.collection.to_sym)
    end

    def render body, options={}
      Rack::JSON::Response.new(body, options).to_a
    end
  end
end