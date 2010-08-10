module Rack::JSON
  class Document

    attr_accessor :attributes

    class BadDocumentFormatError < ArgumentError ; end

    def self.create(doc)
      if doc.is_a? String
        Rack::JSON::JSONDocument.new(doc)
      elsif doc.is_a? BSON::OrderedHash
        Rack::JSON::MongoDocument.new(doc)
      else
        raise Rack::JSON::Document::BadDocumentFormatError
      end
    end


    def add_attributes(pair)
      attributes.merge!(pair)
    end

    def set_id(val)
      add_attributes('_id' => val) unless attributes.keys.include? '_id'
    end

    def to_h
      attributes
    end

    def to_json
      attributes.to_json
    end

    private

    def set_attributes
      private_methods.each do |method|
        if method.match /^set_attribute_\w*$/
          send method
        end
      end
    end

  end
end