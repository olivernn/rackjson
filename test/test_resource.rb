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
    Rack::JSON::Resource.new Object.new,  :collections => [:testing], :db => @db 
  end

  def test_index_method
    @collection.save({:testing => true})
    get '/testing'
    assert last_response.ok?
    assert last_response.body.include? '"testing":true'
  end

  def test_creating_a_document
    put '/testing/1', '{"title": "testing"}'
    assert last_response.ok?
    assert last_response.body.include? '"_id":1'
    assert last_response.body.include? '"title":"testing"'
  end

  def test_index_method_with_query_parameters
    @collection.save({:testing => true, :rating => 5, :title => 'testing'})
    get '/testing?[?title=testing]'
    assert last_response.ok?
    assert last_response.body.include? '"title":"testing"'
    get '/testing?[?rating=5]'
    assert last_response.ok?
    assert last_response.body.include? '"title":"testing"'
  end

  def test_updating_a_document
    @collection.save({:title => 'testing', :_id => 1})
    put '/testing/1', '{"title": "testing update"}'
    assert last_response.ok?
    assert last_response.body.include? '"_id":1'
    assert last_response.body.include? '"title":"testing update"'
  end

  def test_deleting_a_document
    @collection.save({:title => 'testing', :_id => 1})
    assert @collection.find_one({:_id => 1})
    delete '/testing/1'
    assert last_response.ok?
    assert @collection.find_one({:_id => 1}).nil?
  end

  def test_posting_a_document
    post '/testing', '{"title": "testing"}'
    assert last_response.status == 201
    assert last_response.body.include? '"title":"testing"'
  end
end