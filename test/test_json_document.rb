require 'helper'

class JSONDocumentTest < Test::Unit::TestCase

  def test_parsing_simple_json_structure
    hash = { "title" => "testing" }
    doc  = JSON.generate hash
    assert_equal hash["title"], Rack::JSON::JSONDocument.new(doc).attributes["title"]
  end
  
  def test_parsing_nested_json_structure
    hash = { "title" => "nested", "nest" => { "note" => "im nested" } }
    doc = JSON.generate hash
    assert_equal hash["nest"], Rack::JSON::JSONDocument.new(doc).attributes["nest"]
    assert_equal hash["title"], Rack::JSON::JSONDocument.new(doc).attributes["title"]
  end
  
  def test_parsing_dates_from_json
    hash = { "date" => "2010-04-10T14:20:12Z" }
    doc = JSON.generate hash
    assert_equal( Time.parse("2010-04-10T14:20:12Z") , Rack::JSON::JSONDocument.new(doc).attributes["date"])
  end
  
  def test_parsing_mongo_object_id
    hash = { "_id" => "4ba7e82ca04014011c000001" }
    doc = JSON.generate hash
    assert_equal(BSON::ObjectID.from_string("4ba7e82ca04014011c000001"), Rack::JSON::JSONDocument.new(doc).attributes["_id"])
  end
  
  def test_parsing_non_mongo_object_ids
    hash = { "_id" => 1 }
    doc = JSON.generate hash
    assert_equal(hash["_id"], Rack::JSON::JSONDocument.new(doc).attributes["_id"])
  end
  
  def test_adding_an_id
    hash = { "test" => "I don't have an ID" }
    doc = JSON.generate hash
    json_doc = Rack::JSON::JSONDocument.new(doc)
    json_doc.add_id(1)
    assert_equal(1, json_doc.attributes["_id"])
  end
  
  def test_not_overriding_an_id
    hash = { "test" => "I do have an ID", "_id" => 2 }
    doc = JSON.generate hash
    json_doc = Rack::JSON::JSONDocument.new(doc)
    json_doc.add_id(1)
    assert_equal(2 , json_doc.attributes["_id"])
  end
  
  def test_adding_timestamps
    hash = { "_id" => 1 }
    doc = JSON.generate hash
    t = Time.now
    assert_equal(t.to_s, Rack::JSON::JSONDocument.new(doc).attributes["created_at"].to_s)
    assert_equal(t.to_s, Rack::JSON::JSONDocument.new(doc).attributes["updated_at"].to_s)
  end

  def test_not_always_updating_created_at
    hash = { "_id" => 1 }
    doc = JSON.generate hash
    t1 = Time.now
    assert_equal(t1.to_s, Rack::JSON::JSONDocument.new(doc).attributes["created_at"].to_s)
    assert_equal(t1.to_s, Rack::JSON::JSONDocument.new(doc).attributes["updated_at"].to_s)
    sleep 1
    hash2 = { "_id" => 1, "created_at" => t1.to_s }
    doc = JSON.generate hash2
    t2 = Time.now
    assert_equal(t1.to_s, Rack::JSON::JSONDocument.new(doc).attributes["created_at"].to_s)
    assert_equal(t2.to_s, Rack::JSON::JSONDocument.new(doc).attributes["updated_at"].to_s)
  end
end