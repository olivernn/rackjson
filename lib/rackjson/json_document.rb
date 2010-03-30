module Rack::JSON
  class JSONDocument

    attr_reader :attributes

    def initialize(doc)
      @attributes = JSON.parse(doc)
      set_attributes
    end

    def add_id(id)
      @attributes["_id"] = id unless @attributes["_id"]
    end

    private

    def set_attribute_created_at
      @attributes["created_at"] = Time.now unless @attributes["created_at"]
    end

    def set_attribute_dates
      @attributes.each_pair do |key, value|
        if value.class == String && value.match(/^Date\(\d*\)$/)
          @attributes[key] = Time.at(value.gsub(/\D/, '').to_i)
        end
      end
    end

    def set_attribute_ids
      @attributes["_id"] = Mongo::ObjectID.from_string(@attributes["_id"].to_s)
    rescue Mongo::InvalidObjectID
      return false
    end

    def set_attribute_updated_at
      @attributes["updated_at"] = Time.now
    end

    def set_attributes
      private_methods.each do |method|
        if method.match /^set_attribute_\w*$/
          send method
        end
      end
    end
  end
end