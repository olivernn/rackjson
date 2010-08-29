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

    def field(field_names)
      attrs = attributes
      Array.wrap(field_names).each do |field_name|
        if attrs.is_a? Array
          attrs = attrs[field_name.to_i]
        else
          attrs = attrs[field_name]
        end
      end
      attrs
    end

    def set_id(val)
      add_attributes('_id' => val) unless attributes.keys.include? '_id'
    end

    def to_h
      attributes
    end

    def to_json(options={})
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