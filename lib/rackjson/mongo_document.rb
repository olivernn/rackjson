module Rack::JSON
  class MongoDocument

    attr_accessor :attributes

    def initialize(row)
      @attributes = row
      set_created_at
      set_attributes
    end

    private

    def set_attribute_ids
      @attributes["_id"] = @attributes["_id"].to_s if (@attributes["_id"].class == Mongo::ObjectID)
    end

    def set_created_at
      if @attributes["_id"].class == Mongo::ObjectID
        @attributes["created_at"] = @attributes["_id"].generation_time
      end
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