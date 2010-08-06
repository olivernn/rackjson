module Rack::JSON
  class Collection
    def initialize(collection)
      @collection = collection
    end

    # convinience method for testing
    def all(options={})
      @collection.find({}, options).to_a
    end

    def delete(selector={})
      @collection.remove(prepared(selector))
    end

    # convinience method for testing
    def delete_all
      @collection.remove
    end

    def exists?(selector)
      !@collection.find(prepared(selector)).to_a.empty?
    end

    def find(selector, options={})
      @collection.find(selector, options).inject([]) {|documents, row| documents << Rack::JSON::Document.new(row)}
    end

    def find_one(selector, options={})
      find(prepared(selector), options).first
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
      selector.is_a?(Hash) ? selector : {:_id => selector}
    end
  end
end