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

    def apply_filters(request)
      @filters.each do |filter|
        return pre_condition_not_met_for filter unless request.session[filter.to_s]
        request.add_query_param("[?#{filter}=#{request.session[filter.to_s]}]")
      end
      @app.call(request)
    end

    def bypass?(request)
      !(@collections.include? request.collection.to_sym)
    end

    def pre_condition_not_met_for filter
      Rack::JSON::Response.new("pre condition not met", :status => 412, :head => true).to_a
    end
  end
end