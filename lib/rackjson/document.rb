module Rack::JSON
  class Document

    def initialize(doc)
      if doc.is_a? String
        @document = Rack::JSON::JSONDocument.new(doc)
      else doc.is_a? OrderedHash
        @document = Rack::JSON::MongoDocument.new(doc)
      end
    end

    def add_attributes(pair)
      @document.attributes.merge!(pair)
    end

    def method_missing(name, *args)
      @document.send(name, *args)
    end

    def to_json(*a)
      unless @json
        gen_attrs = @document.attributes
        gen_attrs.each_pair do |key, value|
          if value.is_a? BSON::ObjectID
            gen_attrs[key] = gen_attrs[key].to_s
          end
        end
      end
      gen_attrs.to_json
    end
  end
end