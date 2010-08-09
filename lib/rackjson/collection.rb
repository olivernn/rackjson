module Rack::JSON
  class Collection
    def initialize(collection)
      @collection = collection
    end

    def delete(selector={})
      @collection.remove(prepared(selector))
    end

    def exists?(selector)
      !@collection.find(prepared(selector)).to_a.empty?
    end

    def find(selector, options={})
      @collection.find(selector, options).inject([]) {|documents, row| documents << Rack::JSON::Document.create(row)}
    end

    def find_one(selector, options={})
      find(prepared(selector), options).first
    end

    def save(document)
      @collection.save(document.to_h)
    end

    def update(selector, document, query={})
      if exists?(prepared(selector).merge(query))
        @collection.update(prepared(selector).merge(query), document.to_h, :upsert => false)
      else
        false
      end
    end

    private

    def prepared selector
      selector.is_a?(Hash) ? selector : {:_id => selector}
    end
  end
end