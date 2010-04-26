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

    def append_filter_params_to_document_in request
      document = Rack::JSON::Document.new(request.json)
      document.add_attributes(request.session.reject { |key, value| !@filters.include?(key.to_sym) })
      request.set_body(document.to_json)
    end

    def apply_filters(request)
      @filters.each do |filter|
        return pre_condition_not_met_for filter unless request.session[filter.to_s]
        request.add_query_param "[?#{filter}=#{request.session[filter.to_s]}]"
      end
      append_filter_params_to_document_in request if request.post? || request.put?
      @app.call(request.env)
    end

    def bypass?(request)
      request.collection.empty? || !(@collections.include? request.collection.to_sym)
    end

    def pre_condition_not_met_for filter
      Rack::JSON::Response.new("pre condition not met", :status => 412, :head => true).to_a
    end
  end
end