require 'helper'

class MongoDocumentTest < Test::Unit::TestCase

  def test_stringifying_mongo_object_ids
    hash = { "_id" => BSON::ObjectID.from_string("4ba7e82ca04014011c000001") }
    doc = Rack::JSON::MongoDocument.new(hash).attributes
    assert_equal("4ba7e82ca04014011c000001", doc["_id"])
  end

  def test_not_stringifying_non_mongo_object_ids
    hash = { "_id" => 1 }
    doc = Rack::JSON::MongoDocument.new(hash).attributes
    assert_equal({ "_id" => 1 }, doc)
  end

  def test_setting_the_created_at_stamp
    hash = { "_id" => BSON::ObjectID.from_string("4ba7e82ca04014011c000001") }
    doc = Rack::JSON::MongoDocument.new(hash).attributes
    assert_equal({ "_id" => "4ba7e82ca04014011c000001", 
                   "created_at" => BSON::ObjectID.from_string("4ba7e82ca04014011c000001").generation_time
                 }, doc)
  end
end