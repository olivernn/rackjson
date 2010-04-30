require 'helper'

class BuilderTest < Test::Unit::TestCase
  include Rack::Test::Methods
  include Rack::Utils

  def setup
    @db = Mongo::Connection.new.db("test")
    @collection = @db['testing']
  end

  def teardown
    @collection.drop
  end

  def public_resource_app
    Rack::Builder.app do
      use Rack::Session::Cookie
      public_resource :collections => [:testing], :filters => [:user_id], :db => Mongo::Connection.new.db("test")
      run lambda { |env|
        # this is doing some pretend login by simply setting a session var
        request = Rack::JSON::Request.new(env)
        env['rack.session'] = {}
        env['rack.session']['user_id'] = 1
        [200, {'Content-Length' => "6", 'Content-Type' => 'text/plain'}, ["Hello!"]]
      }
    end
  end

  def private_resource_app
    Rack::Builder.app do
      use Rack::Session::Cookie
      private_resource :collections => [:testing], :filters => [:user_id], :db => Mongo::Connection.new.db("test")
      run lambda { |env|
        # this is doing some pretend login by simply setting a session var
        request = Rack::JSON::Request.new(env)
        env['rack.session'] = {}
        env['rack.session']['user_id'] = 1
        [200, {'Content-Length' => "6", 'Content-Type' => 'text/plain'}, ["Hello!"]]
      }
    end
  end

  def expose_resource_app
    Rack::Builder.app do
      expose_resource :collections => [:testing], :db => Mongo::Connection.new.db("test")
      run lambda { |env| [404, {'Content-Length' => '9', 'Content-Type' => 'text/plain'}, ["Not Found"]] }
    end
  end

  def use_expose_resource
    BuilderTest.class_eval { def app; expose_resource_app; end }
  end

  def use_public_resource
    BuilderTest.class_eval { def app; public_resource_app; end }
  end

  def use_private_resource
    BuilderTest.class_eval { def app; private_resource_app; end }
  end

  test "using expose_resource we can still bypass rack json" do
    BuilderTest.class_eval { def app; expose_resource_app; end }

    get '/blah'
    assert_equal 404, last_response.status
  end

  test "using expose_resource still gives access to Rack::JSON::Resource" do
    use_expose_resource

    @collection.save({:testing => true})
    get '/testing'
    assert last_response.ok?
    assert_match /"testing":true/, last_response.body
  end

  test "using public_resource still can bypass Rack::JSON" do
    use_public_resource

    get '/blah'
    assert_equal 200, last_response.status
  end

  test "using public_resource still gives access to Rack::JSON::Resource" do
    use_public_resource

    @collection.save({:testing => true})
    get '/testing'
    assert last_response.ok?
    assert_match /"testing":true/, last_response.body
  end

  test "using public_resource should restrict non get requests to the resources" do
    use_public_resource

    post '/testing', '{"test":"yes"}'
    assert_equal 412, last_response.status
  end

  test "using public resource should not restrict requests when the pre-conditions are met" do
    use_public_resource

    get '/login' # pretend to login
    post '/testing', '{"test":"yes"}'
    assert_equal 201, last_response.status
  end

  test "using private resource should restrict all requests to the resource" do
    use_private_resource

    get '/testing'
    assert_equal 412, last_response.status
  end

  test "using private resource should not restrict requests when the pre-conditions are met" do
    use_private_resource

    get '/login' # pretend to login
    get '/testing'
    assert last_response.ok?
  end
end