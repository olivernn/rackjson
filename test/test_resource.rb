require 'helper'

class ResourceTest < Test::Unit::TestCase
  include Rack::Test::Methods
  include Rack::Utils
  def setup
    @db = Mongo::Connection.new.db("test")
    @collection = @db['testing']
  end

  def teardown
    @collection.drop
  end

  def app
    Rack::JSON::Resource.new lambda { |env| 
      [404, {'Content-Length' => '9', 'Content-Type' => 'text/plain'}, "Not Found"]
    },  :collections => [:testing], :db => @db 
  end

  def test_non_existing_resource
    get '/blah'
    assert_equal 404, last_response.status
  end

  def test_index_method
    @collection.save({:testing => true})
    get '/testing'
    assert last_response.ok?
    assert_match /"testing":true/, last_response.body
  end

  def test_creating_a_document
    put '/testing/1', '{"title": "testing"}'
    assert_equal 201, last_response.status
    assert_match /"_id":1/, last_response.body
    assert_match /"title":"testing"/, last_response.body
  end

  def test_show_a_single_document
    put '/testing/1', '{"title": "testing first"}'
    put '/testing/2', '{"title": "testing second"}'
    get '/testing/1'
    assert last_response.ok?
    assert_match /"title":"testing first"/, last_response.body
    assert_no_match /"title":"testing second"/, last_response.body
  end

  def test_not_finding_a_specific_document
    get '/testing/1'
    assert_equal 404, last_response.status
    assert_equal "document not found", last_response.body
  end

  def test_index_method_with_query_parameters
    @collection.save({:testing => true, :rating => 5, :title => 'testing'})
    get '/testing?[?title=testing]'
    assert last_response.ok?
    assert_match /"title":"testing"/, last_response.body
    get '/testing?[?rating=5]'
    assert last_response.ok?
    assert_match /"title":"testing"/, last_response.body
  end

  def test_index_method_with_sort
    @collection.save({:testing => true, :rating => 5, :title => 'testing'})
    get '/testing?[/title]'
    assert last_response.ok?
    assert_match /"title":"testing"/, last_response.body
    get '/testing?[?rating=5]'
    assert last_response.ok?
    assert_match /"title":"testing"/, last_response.body
  end

  def test_putting_a_new_document
    put '/testing/1', '{"title": "testing update"}'
    assert_equal 201, last_response.status
    assert_match /"_id":1/, last_response.body
    assert_match /"title":"testing update"/, last_response.body
  end

  def test_updating_a_document
    @collection.save({:title => 'testing', :_id => 1})
    put '/testing/1', '{"title": "testing update"}'
    assert last_response.ok?
    assert_match /"_id":1/, last_response.body
    assert_match /"title":"testing update"/, last_response.body
  end

  def test_deleting_a_document
    @collection.save({:title => 'testing', :_id => 1})
    assert @collection.find_one({:_id => 1})
    delete '/testing/1'
    assert last_response.ok?
    assert_nil @collection.find_one({:_id => 1})
  end

  def test_deleting_only_with_member_path
    delete '/testing'
    assert_equal 405, last_response.status
  end

  def test_posting_a_document
    post '/testing', '{"title": "testing"}'
    assert last_response.status == 201
    assert_match /"title":"testing"/, last_response.body
  end
end