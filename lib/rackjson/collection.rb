require 'enumerator'

module Rack::JSON
  class Collection

    class Rack::JSON::Collection::DataTypeError < TypeError ; end

    def initialize(collection)
      @collection = collection
    end

    def delete(selector={})
      @collection.remove(prepared(selector))
    end

    def delete_field(selector, field)
      _update(prepared(selector), { "$unset" => { dot_notate(field) => 1 }})
    end

    def exists?(selector)
      !@collection.find(prepared(selector)).to_a.empty?
    end

    def find(selector, options={})
      @collection.find(selector, options).inject([]) {|documents, row| documents << Rack::JSON::Document.create(row)}
    end

    def find_field(selector, fields, options={})
      document = find_one(prepared(selector))
      document ? document.field(fields) : nil
    end

    def find_one(selector, options={})
      find(prepared(selector), options).first
    end

    [:increment, :decrement].each do |method_name|
      define_method method_name do |selector, field, *val|
        value = *val.first || 1
        _update(prepared(selector), { "$inc" => { dot_notate(field) => method_name == :increment ? value : (-1 * value) }})
      end
    end

    [:pull, :pull_all, :push, :push_all, :add_to_set].each do |method_name|
      define_method method_name do |selector, field, value|
        modifier = "$#{method_name.to_s.split('_').to_enum.each_with_index.map { |w, i| i == 0 ? w : w.capitalize }.join}"
        _update(prepared(selector), { modifier => { dot_notate(field) => value }})
      end
    end

    def save(document)
      @collection.save(document.to_h)
    end

    def update(selector, document, query={})
      if exists?(prepared(selector).merge(query))
        _update(prepared(selector).merge(query), document.to_h, :upsert => false)
      else
        false
      end
    end

    def update_field(selector, field, value)
      _update(prepared(selector), { "$set" => { dot_notate(field) => value }})
    end

    private

    def dot_notate field
      field.is_a?(Array) ? field.join(".") : field
    end

    def prepared selector
      selector.is_a?(Hash) ? selector : {:_id => selector}
    end

    def _update(query, hash, options={})
      @collection.update(query, hash, options)
    end
  end
end