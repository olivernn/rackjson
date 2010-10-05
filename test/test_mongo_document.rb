require 'helper'

class MongoDocumentTest < Test::Unit::TestCase

  def test_stringifying_mongo_object_ids
    hash = {"_id" => BSON::ObjectId.from_string("4ba7e82ca04014011c000001")}
    doc = Rack::JSON::MongoDocument.new(hash).attributes
    assert_equal("4ba7e82ca04014011c000001", doc["_id"])
  end

  def test_not_stringifying_non_mongo_object_ids
    hash = { "_id" => 1 }
    doc = Rack::JSON::MongoDocument.new(hash).attributes
    assert_equal(1, doc["_id"])
  end
end