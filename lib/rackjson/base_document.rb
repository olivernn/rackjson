module Rack::JSON
  module BaseDocument

    private

    def set_attribute_created_at
      @attributes["created_at"] = Time.now unless @attributes["created_at"]
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