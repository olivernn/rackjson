require 'helper'

class DocumentTest < Test::Unit::TestCase

  def setup
    @db = Mongo::Connection.new.db("test")
    @collection = @db['resource_test']
  end

  def teardown
    @collection.drop
  end

  def test_adding_attributes_to_the_document
    json = '{"test":"hello"}'
    document = Rack::JSON::Document.new(json)
    document.add_attributes("user_id" => 1)
    assert_equal(1, document.attributes["user_id"])
  end

  def test_creating_from_json
    json = '{"test":"hello"}'
    document = Rack::JSON::Document.new(json)
    assert_equal("hello", document.attributes["test"])
    assert_equal(Time.now.to_s, document.attributes["created_at"].to_s)
    assert_equal(Time.now.to_s, document.attributes["updated_at"].to_s)
  end

  def test_creating_from_json_with_id
    json = '{"_id": "4b9f783ba040140525000001", "test":"hello"}'
    document = Rack::JSON::Document.new(json)
    assert_equal(BSON::ObjectID.from_string('4b9f783ba040140525000001'), document.attributes["_id"])
    assert_equal("hello", document.attributes["test"])
    assert_equal(Time.now.to_s, document.attributes["created_at"].to_s)
    assert_equal(Time.now.to_s, document.attributes["updated_at"].to_s)
  end

  def test_creating_from_json_with_non_object_id
    json = '{"_id": 1, "test":"hello"}'
    document = Rack::JSON::Document.new(json)
    assert_equal(1, document.attributes["_id"])
    assert_equal("hello", document.attributes["test"])
    assert_equal(Time.now.to_s, document.attributes["created_at"].to_s)
    assert_equal(Time.now.to_s, document.attributes["updated_at"].to_s)
  end

  def test_adding_id
    json = '{"test":"hello"}'
    document = Rack::JSON::Document.new(json)
    id = @collection.insert(document.attributes)
    document.add_id(id)
    assert_equal(id.to_s, document.attributes[:_id].to_s)
  end

  def test_creating_from_row
    @collection.insert({"test"=>"hello"})
    rows = []
    @collection.find.each { |r| rows << r }
    document = Rack::JSON::Document.new(rows.first)
    assert_equal("hello", document.attributes["test"])
  end

  def test_document_created_at
    json = '{"test":"hello", "created_at": "01/01/2010"}'
    document = Rack::JSON::Document.new(json)
    assert_equal("hello", document.attributes["test"])
    assert_equal("01/01/2010", document.attributes["created_at"])
    assert_equal(Time.now.to_s, document.attributes["updated_at"].to_s)
  end
end