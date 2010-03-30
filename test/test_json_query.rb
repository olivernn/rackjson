require 'helper'

class QueryTest < Test::Unit::TestCase
  def test_ascending_sort
    json_query = "[/price]"
    query  = Rack::JSON::JSONQuery.new(json_query)
    assert_equal({:sort => [:price, :asc]}, query.options)
  end

  def test_descending_sort
    json_query = '[\price]'
    query  = Rack::JSON::JSONQuery.new(json_query)
    assert_equal({:sort => [:price, :desc]}, query.options)
  end

  def test_skips_and_limits
    json_query = '[0:10]'
    query = Rack::JSON::JSONQuery.new(json_query)
    assert_equal({:skip => 0, :limit => 10}, query.options)
  end

  def test_map_query
    json_query = '[=name]'
    query = Rack::JSON::JSONQuery.new(json_query)
    assert_equal({:fields => ['name']}, query.options)
  end

  def test_single_equality_condition_with_number
    json_query = '[?price=10]'
    query = Rack::JSON::JSONQuery.new(json_query)
    assert_equal({:price => 10}, query.selector)
  end

  def test_single_equality_condition_with_string
    json_query = '[?name=bob!]'
    query = Rack::JSON::JSONQuery.new(json_query)
    assert_equal({:name => 'bob!'}, query.selector)
  end

  def test_single_greater_than_condition
    json_query = '[?price>10]'
    query = Rack::JSON::JSONQuery.new(json_query)
    assert_equal({:price => {'$gt' => 10}}, query.selector)
  end

  def test_single_greater_than_or_equal_condition
    json_query = '[?price>=10]'
    query = Rack::JSON::JSONQuery.new(json_query)
    assert_equal({:price => { '$gte' => 10}}, query.selector)
  end

  def test_single_less_than_condition
    json_query = '[?price<10]'
    query = Rack::JSON::JSONQuery.new(json_query)
    assert_equal({:price => {'$lt' => 10}}, query.selector)
  end

  # def test_single_greater_than_or_equal_condition
  #   json_query = '[?price=<10]'
  #   query = Rack::JSON::JSONQuery.new(json_query)
  #   assert_equal({:price => { '$lte' => 10}}, query.selector)
  # end
end