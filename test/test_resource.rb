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

  test "finding a field within a specific document" do
    @collection.save({:testing => true, :rating => 5, :title => 'testing', :_id => 1})
    get '/testing/1/title'
    assert last_response.ok?
    assert_equal "testing", last_response.body
  end

  test "finding an array inside a document" do
    @collection.save({:obj => { :hello => "world"}, :ratings => [5,2], :title => 'testing', :_id => 1})
    get '/testing/1/ratings'
    assert last_response.ok?
    expected = [5,2]
    assert_equal expected, JSON.parse(last_response.body)
  end

  test "finding an element of an array from a specific document" do
    @collection.save({:testing => true, :ratings => [5,2], :title => 'testing', :_id => 1})
    get '/testing/1/ratings/0'
    assert last_response.ok?
    assert_equal "5", last_response.body
  end

  test "finding an embedded document" do
    @collection.save({:obj => { :hello => "world"}, :ratings => [5,2], :title => 'testing', :_id => 1})
    get '/testing/1/obj'
    assert last_response.ok?
    expected = { "hello" => "world" }
    assert_equal expected, JSON.parse(last_response.body)
  end

  test "finding a property of an embedded document" do
    @collection.save({:obj => { :hello => "world"}, :ratings => [5,2], :title => 'testing', :_id => 1})
    get '/testing/1/obj/hello'
    assert last_response.ok?
    assert_equal "world", last_response.body
  end

  test "modifying a property of an embedded document" do
    @collection.save({:obj => { :counter => 1}, :_id => 1})
    put '/testing/1/obj/counter/_increment'
    assert last_response.ok?
    assert_equal 2, @collection.find_one(:_id => 1)["obj"]["counter"]
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

  test "updating a field within a document" do
    @collection.save({:title => 'testing', :_id => 1})
    put '/testing/1/title', '{"value": "updated"}'
    assert last_response.ok?
    assert_equal "updated", @collection.find_one(:_id => 1)['title']
  end

  test "creating a new field within an existing documennt" do
    @collection.save({:title => 'testing', :_id => 1})
    put '/testing/1/new_field', '{"value": "created"}'
    assert last_response.ok?
    assert_equal "created", @collection.find_one(:_id => 1)['new_field']
  end

  test "trying to create a new field within a non-existant document" do
    @collection.save({:title => 'testing', :_id => 1})
    put '/testing/2/title', '{"value": "updated"}'
    assert_equal 404, last_response.status
  end

  test "incrementing a value within a document" do
    @collection.save({:counter => 1, :_id => 1})
    put '/testing/1/counter/_increment'
    assert last_response.ok?
    assert_equal 2, @collection.find_one(:_id => 1)["counter"]
  end

  test "incrementing a non existant field" do
    @collection.save({:_id => 1})
    put '/testing/1/counter/_increment'
    assert last_response.ok?
    assert_equal 1, @collection.find_one(:_id => 1)["counter"]
  end

  test "incrementing a value within a document by a custom amount" do
    @collection.save({:counter => 1, :_id => 1})
    put '/testing/1/counter/_increment', '{"value" : 10}'
    assert last_response.ok?
    assert_equal 11, @collection.find_one(:_id => 1)["counter"]
  end

  test "incrementing a value on a non existent document" do
    put '/testing/1/counter/_increment'
    assert_equal 404, last_response.status
  end

  test "decrementing a value within a document" do
    @collection.save({:counter => 1, :_id => 1})
    put '/testing/1/counter/_decrement'
    assert last_response.ok?
    assert_equal 0, @collection.find_one(:_id => 1)["counter"]
  end

  test "push a simple value onto an array within a document" do
    @collection.save({:list => [1,2,3], :_id => 1})
    put '/testing/1/list/_push', '{"value" : 4}'
    assert last_response.ok?
    assert_equal [1,2,3,4], @collection.find_one(:_id => 1)['list']
  end

  test "push an object onto an array within a document" do
    @collection.save({:list => [1,2,3], :_id => 1})
    put '/testing/1/list/_push', '{"value" : { "foo": "bar" }}'
    assert last_response.ok?
    assert_equal [1,2,3,{"foo" => "bar"}], @collection.find_one(:_id => 1)['list']
  end

  test "push more than one item onto an array within a document" do
    @collection.save({:list => [1,2,3], :_id => 1})
    put '/testing/1/list/_push_all', '{"value" : [4,5,6,7]}'
    assert last_response.ok?
    assert_equal [1,2,3,4,5,6,7], @collection.find_one(:_id => 1)['list']
  end

  test "pull a simple value from an array within a document" do
    @collection.save({:list => [1,2,3], :_id => 1})
    put '/testing/1/list/_pull', '{"value" : 2}'
    assert last_response.ok?
    assert_equal [1,3], @collection.find_one(:_id => 1)['list']
  end

  test "pull an object from an array within a document" do
    @collection.save({:list => [1,2,3,{"foo" => "bar"}], :_id => 1})
    put '/testing/1/list/_pull', '{"value" : { "foo": "bar" }}'
    assert last_response.ok?
    assert_equal [1,2,3], @collection.find_one(:_id => 1)['list']
  end

  test "pull more than one item from an array within a document" do
    @collection.save({:list => [1,2,3,4,5,6,7], :_id => 1})
    put '/testing/1/list/_pull_all', '{"value" : [4,5,6,7]}'
    assert last_response.ok?
    assert_equal [1,2,3], @collection.find_one(:_id => 1)['list']
  end

  # requires mongodb version > 1.3
  # test "adding an item to a set" do
  #   @collection.save({:list => [1,2,3], :_id => 1})
  #   put '/testing/1/list/_add_to_set', '{"value" : 4}'
  #   assert last_response.ok?
  #   assert_equal [1,2,3,4], @collection.find_one(:_id => 1)['list']
  # end

  test "deleting a document" do
    @collection.save({:title => 'testing', :_id => 1})
    assert @collection.find_one({:_id => 1})
    delete '/testing/1'
    assert last_response.ok?
    assert_nil @collection.find_one({:_id => 1})
  end

  test "deleting a field within a document" do
    @collection.save({:title => 'testing', :_id => 1})
    assert @collection.find_one({:_id => 1})
    delete '/testing/1/title'
    assert last_response.ok?
    assert_nil @collection.find_one({:_id => 1})['title']
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