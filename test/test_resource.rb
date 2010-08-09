require 'helper'

class ResourceTest < Test::Unit::TestCase
  include Rack::Test::Methods
  include Rack::Utils
  def setup
    @db = Mongo::Connection.new.db("test")
    @collection = @db['testing']
    use_basic_resource
  end

  def teardown
    @collection.drop
  end

  def app
    Rack::JSON::Resource.new lambda { |env|
      [404, {'Content-Length' => '9', 'Content-Type' => 'text/plain'}, ["Not Found"]]
    },  :collections => [:testing], :db => @db
  end

  def basic_app
    Rack::JSON::Resource.new lambda { |env|
      [404, {'Content-Length' => '9', 'Content-Type' => 'text/plain'}, ["Not Found"]]
    },  :collections => [:testing], :db => @db
  end

  def get_only_app
    Rack::JSON::Resource.new lambda { |env|
      [404, {'Content-Length' => '9', 'Content-Type' => 'text/plain'}, ["Not Found"]]
    },  :collections => [:testing], :db => @db, :only => [:get]
  end

  def no_delete_app
    Rack::JSON::Resource.new lambda { |env|
      [404, {'Content-Length' => '9', 'Content-Type' => 'text/plain'}, ["Not Found"]]
    },  :collections => [:testing], :db => @db, :except => [:delete]
  end

  def use_basic_resource
    ResourceTest.class_eval { def app; basic_app; end }
  end

  def use_get_only_resource
    ResourceTest.class_eval { def app; get_only_app; end }
  end

  def use_no_delete_resource
    ResourceTest.class_eval { def app; no_delete_app; end }
  end

  test "get non existing resource" do
    get '/blah'
    assert_equal 404, last_response.status
  end

  test "post non existing resource" do
    post '/blah', '{ "title": "hello!" }'
    assert_equal 404, last_response.status
  end

  test "get root" do
    get '/'
    assert_equal 404, last_response.status
  end

  test "index method" do
    @collection.save({:testing => true})
    get '/testing'
    assert last_response.ok?
    assert_match /"testing":true/, last_response.body
  end

  test "creating a document" do
    put '/testing/1', '{"title": "testing"}'
    assert_equal 201, last_response.status
    assert_match /"_id":1/, last_response.body
    assert_match /"title":"testing"/, last_response.body
  end

  test "show a single document" do
    put '/testing/1', '{"title": "testing first"}'
    post '/testing', '{"title": "testing second"}'
    get '/testing/1'
    assert last_response.ok?
    assert_match /"title":"testing first"/, last_response.body
    assert_no_match /"title":"testing second"/, last_response.body
    assert_instance_of Hash, JSON.parse(last_response.body)
  end

  test "not finding a specific document" do
    get '/testing/1'
    assert_equal 404, last_response.status
    assert_equal "document not found", last_response.body
  end

  test "index method with query parameters" do
    @collection.save({:testing => true, :rating => 5, :title => 'testing'})
    get '/testing?[?title=testing]'
    assert last_response.ok?
    assert_match /"title":"testing"/, last_response.body
    get '/testing?[?rating=5]'
    assert last_response.ok?
    assert_match /"title":"testing"/, last_response.body
  end

  test "index method with sort" do
    @collection.save({:testing => true, :rating => 5, :title => 'testing'})
    get '/testing?[/title]'
    assert last_response.ok?
    assert_match /"title":"testing"/, last_response.body
    get '/testing?[?rating=5]'
    assert last_response.ok?
    assert_match /"title":"testing"/, last_response.body
  end

  test "putting a new document" do
    put '/testing/1', '{"title": "testing update"}'
    assert_equal 201, last_response.status
    assert_match /"_id":1/, last_response.body
    assert_match /"title":"testing update"/, last_response.body
  end

  test "updating a document" do
    @collection.save({:title => 'testing', :_id => 1})
    put '/testing/1', '{"title": "testing update"}'
    assert_match /"_id":1/, last_response.body
    assert_match /"title":"testing update"/, last_response.body
  end

  test "updating a document with matching query params" do
    @collection.save({:title => 'testing', :_id => 1, :user_id => 1})
    put '/testing/1?[?user_id=1]', '{"title": "testing update"}'
    assert last_response.ok?
    assert_match /"_id":1/, last_response.body
    assert_match /"title":"testing update"/, last_response.body
  end

  test "updating a document with non matching query params" do
    @collection.save({:title => 'testing', :_id => 1, :user_id => 2})
    put '/testing/1?[?user_id=1]', '{"title": "testing update"}'
    assert_equal 404, last_response.status
    assert_equal @collection.find_one(:_id => 1)["title"], 'testing'
    assert_nil @collection.find_one(:_id => 1, :user_id => 1)
  end

  test "deleting a document" do
    @collection.save({:title => 'testing', :_id => 1})
    assert @collection.find_one({:_id => 1})
    delete '/testing/1'
    assert last_response.ok?
    assert_nil @collection.find_one({:_id => 1})
  end

  test "deleting only with member path" do
    delete '/testing'
    assert_equal 405, last_response.status
  end

  test "posting a document" do
    post '/testing', '{"title": "testing"}'
    assert last_response.status == 201
    assert_match /"title":"testing"/, last_response.body
  end

  test "using a string id for a document" do
    put '/testing/string-id-1', '{"title": "testing"}'
    put '/testing/another-string-id-2', '{"foo": "bar"}'
    assert last_response.status == 201
    get '/testing/string-id-1'
    assert_equal 'testing', @collection.find_one({:_id => 'string-id-1'})['title']
    assert_no_match /"foo":"bar"/, last_response.body
    assert_match /"title":"testing"/, last_response.body
  end

  test "restricting the http methods supported using the 'only' option" do
    use_get_only_resource

    post '/testing', '{"title": "testing"}'
    assert last_response.status == 405
  end

  test "restricting the http methods supported using the 'except' option" do
    use_no_delete_resource

    delete 'testing/1'
    assert last_response.status == 405
  end
end