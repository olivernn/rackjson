require 'helper'

class CollectionTest < Test::Unit::TestCase

  def setup
    @db = Mongo::Connection.new.db("test")
    @doc = @db['resource_test'].insert({:_id => 1, :count => 1, :field => 'foo', :array => [1,2,3,4], :obj => { :field => 'baz'}})
    @collection = Rack::JSON::Collection.new(@db['resource_test'])
  end

  def teardown
    @db['resource_test'].drop
  end

  test "should be able to retrieve a specific element from a document in the collection" do
    assert_equal('foo', @collection.find_field(1, 'field'))
  end

  test "should return nil if there is no matching field" do
    assert_nil(@collection.find_field(1, 'non-existant-field'))
  end

  test "should be able to retrieve a specific element form an array" do
    assert_equal(2, @collection.find_field(1, 'array', :property => 1))
  end

  test "should return nil if asking for an array element that doesn't exist" do
    assert_nil(@collection.find_field(1, 'array', :property => 100))
  end

  test "should be able to retrieve a specific element from an embedded object" do
    assert_equal('baz', @collection.find_field(1, 'obj', :property => 'field'))
  end

  test "should return nil if asking for an element that doesn't exist on the embeded object" do
    assert_nil(@collection.find_field(1, 'obj', :property => 'non-existant'))
  end

  test "attomic increment" do
    @collection.increment(1, 'count')
    assert_equal(2, @collection.find_field(1, 'count'))
  end

  test "attomic decrement" do
    @collection.decrement(1, 'count')
    assert_equal(0, @collection.find_field(1, 'count'))
  end
end