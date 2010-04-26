module Rack::JSON
  class Collection
    def initialize(collection)
      @collection = collection
    end

    def all(options={})
      @collection.find({}, options).to_a
    end

    def create(document)
      @collection.save(document)
    end

    def delete(selector={})
      @collection.remove(prepared(selector))
    end

    def delete_all
      @collection.remove
    end

    def exists?(selector)
      !@collection.find(prepared(selector)).to_a.empty?
    end

    def find(selector, options={})
      if selector.is_a? Hash
        @collection.find(selector, options).to_a
      else
        @collection.find_one(:_id => selector)
      end
    end

    def save(document)
      @collection.save(document)
    end

    def update(selector, document, query={})
      if exists?(prepared(selector).merge(query))
        @collection.update(prepared(selector).merge(query), document, :upsert => false)
      else
        false
      end
    end

    private

    def prepared selector
      if selector.is_a? Hash
        selector
      else
        {:_id => selector}
      end
    end

  end
end