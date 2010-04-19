module Rack::JSON
  class Filter

    def initialize(app, options)
      @app = app
      @collections = options[:collections]
      @filters = options[:filters]
    end

    def call(env)
      request = Rack::JSON::Request.new(env)
      if bypass? request
        @app.call(env)
      else
        apply_filters(request)
      end
    end

    private

    def bypass?(request)
      !(@collections.include? request.collection.to_sym)
    end

    def apply_filters(request)
      @filters.each do |filter|
        request.add_query_param("[?#{filter}=#{request.session[filter.to_s]}]") if request.session[filter.to_s]
      end
      @app.call(request)
    end
  end
end