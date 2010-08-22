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

  test "incrementing by more than 1" do
    @collection.increment(1, 'count', 2)
    assert_equal(3, @collection.find_field(1, 'count'))
  end

  test "attomic decrement" do
    @collection.decrement(1, 'count')
    assert_equal(0, @collection.find_field(1, 'count'))
  end

  test "decrementing by more than 1" do
    @collection.decrement(1, 'count', 2)
    assert_equal(-1, @collection.find_field(1, 'count'))
  end

  test "attomic push" do
    @collection.push(1, 'array', 'pushed value')
    assert_equal([1,2,3,4,'pushed value'], @collection.find_field(1, 'array'))
  end

  test "attomic push on a new list" do
    @collection.push(1, 'new-array', 'pushed value')
    assert_equal(['pushed value'], @collection.find_field(1, 'new-array'))
  end

  # mongo isn't throwing an error when doing this, may need to upgrade
  # test "attomic push on a non list field should raise a DataTypeError"

  test "attomic push all on an existing list" do
    @collection.push_all(1, 'array', ["a", "b", "c"])
    assert_equal([1,2,3,4,'a','b','c'], @collection.find_field(1, 'array'))
  end

  test "attomic push all on to create a new list" do
    @collection.push_all(1, 'new-array', ["a", "b", "c"])
    assert_equal(["a", "b", "c"], @collection.find_field(1, 'new-array'))
  end

  test "attomic pull item form a list" do
    @collection.pull(1, 'array', 4)
    assert_equal([1,2,3], @collection.find_field(1, 'array'))
  end

  test "attomic pull all to remove more than one item from a list" do
    @collection.pull_all(1, 'array', [1,2,3])
    assert_equal([4], @collection.find_field(1, 'array'))
  end

  # currently failing because add to set is supported in mongo v1.3+
  # test "adding an element to an array only if it doesn't already exist in the array" do
  #   @collection.add_to_set(1, 'array', 'pushed value')
  #   assert_equal([1,2,3,4,'pushed value'], @collection.find_field(1, 'array'))
  #   @collection.add_to_set(1, 'array', 1)
  #   assert_equal([1,2,3,4,'pushed value'], @collection.find_field(1, 'array'))
  # end
end