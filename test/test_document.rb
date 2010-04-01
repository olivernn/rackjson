require 'helper'

class DocumentTest < Test::Unit::TestCase

  def setup
    @db = Mongo::Connection.new.db("test")
    @collection = @db['resource_test']
  end

  def teardown
    @collection.drop
  end

  def test_creating_from_json
    json = '{"test":"hello"}'
    document = Rack::JSON::Document.new(json)
    assert({:test => "hello", :created_at => Time.now, :updated_at => Time.now}, document.attributes)
  end

  def test_creating_from_json_with_id
    json = '{"_id": "4b9f783ba040140525000001", "test":"hello"}'
    document = Rack::JSON::Document.new(json)
    assert({
        :_id => Mongo::ObjectID.from_string('4b9f783ba040140525000001'), 
        :test => "hello", 
        :created_at => Time.now, 
        :updated_at => Time.now
      }, document.attributes)
  end

  def test_creating_from_json_with_non_object_id
    json = '{"_id": 1, "test":"hello"}'
    document = Rack::JSON::Document.new(json)
    assert({:_id => 1, :test => "hello", :created_at => Time.now, :updated_at => Time.now}, document.attributes)
  end

  def test_adding_id
    json = '{"test":"hello"}'
    document = Rack::JSON::Document.new(json)
    id = @collection.insert(document.attributes)
    document.add_id(id)
    assert(id.to_s, document.attributes[:_id])
  end

  def test_creating_from_row
    @collection.insert({"test"=>"hello"})
    rows = []
    @collection.find.each { |r| rows << r }
    document = Rack::JSON::Document.new(rows.first)
    assert({:test => "hello"}, document.attributes)
  end

  def test_document_created_at
    json = '{"test":"hello", "created_at": "01/01/2010"}'
    document = Rack::JSON::Document.new(json)
    assert({:test => "hello", :created_at => "01/01/2010", :updated_at => Time.now }, document.attributes)
  end
end