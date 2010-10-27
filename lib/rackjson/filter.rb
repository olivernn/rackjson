module Rack::JSON
  class Filter
    include Rack::JSON::EndPoint

    def initialize(app, options)
      @app = app
      @collections = options[:collections]
      @filters = options[:filters]
      @methods = options[:methods]
    end

    def call(env)
      request = Rack::JSON::Request.new(env)
      if bypass_path?(request) || bypass_method?(request)
        @app.call(env)
      else
        apply_filters(request)
      end
    end

    private

    def append_filters_to_document_in request
      document = Rack::JSON::Document.create(request.json)
      document.add_attributes(request.session.reject { |key, value| !@filters.include?(key.to_sym) })
      request.set_body(document.to_json)
    end

    def apply_filters(request)
      raise 'no filters given!' if @filters.nil?
      @filters.each do |filter|
        return pre_condition_not_met unless request.session.keys.include? filter.to_s
        request.add_query_param "[?#{filter}=#{request.session[filter.to_s]}]"
      end
      append_filters_to_document_in request if request.post? || request.put?
      @app.call(request.env)
    rescue JSON::ParserError => error
      return invalid_json error
    end

    def pre_condition_not_met
      render "pre condition not met", :status => 412, :head => true
    end
  end
end