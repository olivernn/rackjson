module Rack::JSON
  class JSONDocument
    include Rack::JSON::BaseDocument

    attr_reader :attributes

    def initialize(doc)
      @attributes = JSON.parse(doc)
      set_attributes
    end

    def add_id(id)
      @attributes["_id"] = id unless @attributes["_id"]
    end

    private

    def set_attribute_dates
      @attributes.each_pair do |key, value|
        if value.class == String && value.match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/)
          @attributes[key] = Time.parse(value)
        end
      end
    end

    def set_attribute_ids
      @attributes["_id"] = BSON::ObjectID.from_string(@attributes["_id"].to_s)
    rescue BSON::InvalidObjectID
      return false
    end

    def set_attribute_updated_at
      @attributes["updated_at"] = Time.now
    end
  end
end