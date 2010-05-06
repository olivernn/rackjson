module Rack::JSON
  class MongoDocument
    include Rack::JSON::BaseDocument

    attr_accessor :attributes

    def initialize(row)
      @attributes = row
      set_attributes
    end

    private

    def set_attribute_ids
      @attributes["_id"] = @attributes["_id"].to_s if (@attributes["_id"].is_a? BSON::ObjectID)
    end
  end
end