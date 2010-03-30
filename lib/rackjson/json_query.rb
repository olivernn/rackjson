module Rack::JSON
  class JSONQuery

    attr_accessor :options, :selector

    def initialize(query_string)
      @query_string = query_string
      @conditions = @query_string.split(/\[|\]/).compact.reject(&:empty?)
      @options = {}
      @selector = {}
      build
    end

    private

    def build
      @conditions.each do |condition|
        private_methods.each do |method|
          if method.match /^set_query_\w*$/
            send method, condition
          end
        end
      end
    end

    def comparison(symbol)
      { 
        '>'  => '$gt',
        '<'  => '$lt',
        '=<' => '$lte',
        '>=' => '$gte'
      }[symbol]
    end

    def set_query_fields(condition)
      if condition.match /^=\w+$/
        @options[:fields] = condition.sub('=', '').split(',')
      end
    end

    def set_query_selector_equality(condition)
      if condition.match /^\?\w+=.+$/
        field = condition.sub('?', '').split('=').first.to_sym
        value = (condition.sub('?', '').split('=').last.match(/^\d+$/) ? condition.sub('?', '').split('=').last.to_f : condition.sub('?', '').split('=').last.to_s)
        @selector[field] = value
      end
    end

    def set_query_selector(condition)
      if condition.match /^\?\w+>=|=<|<|>\d+$/
        field = condition.sub('?', '').split(/>=|=<|<|>/).first.to_sym
        value = condition.sub('?', '').split(/>=|=<|<|>/).last.to_f
        @selector[field] = { comparison(condition.slice(/>=|=<|<|>/)) => value }
      end
    end

    def set_query_skip_limit(condition)
      if condition.match /^\d+:\d+$/
        @options[:skip] = condition.split(':').first.to_i
        @options[:limit] = condition.split(':').last.to_i
      end
    end

    def set_query_sort(condition)
      condition.split(/,\s?/).each do |part|
        if part.match /^[\/|\\]\w*$/
          @options[:sort] ||= []
          @options[:sort] << [part.sub(/[\/|\\]/, '').to_sym, (part.match(/\//) ? :asc : :desc)]
        end
      end
    end
  end
end