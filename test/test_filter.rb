require 'helper'

class FilterTest < Test::Unit::TestCase
  include Rack::Test::Methods
  include Rack::Utils

  def app
    Rack::Session::Cookie.new(
      Rack::JSON::Filter.new lambda { |env|
        request = Rack::JSON::Request.new(env)
        env['rack.session'] = {}
        env['rack.session']['user_id'] = 1
        [200, {'Content-Length' => request.json.length.to_s, 'Content-Type' => 'text/plain'}, [request.json]]
      },  :collections => [:testing], :filters => [:user_id], :methods => @test_methods || [:get, :post, :put, :delete]
    )
  end

  test "adding a user id query parameter" do
    get '/login'
    get '/testing'
    assert_equal "[?user_id=1]", last_request.query_string
  end

  test "dont override any existing query parameters" do
    get '/login'
    get '/testing?[?title=awesome]'
    assert_equal '[?title=awesome][?user_id=1]', URI.decode(last_request.query_string)
  end

  test "reject request if no session var" do
    get '/testing'
    assert_equal 412, last_response.status
  end

  test "setting query parameters on a post request" do
    get '/login'
    post '/testing', '{ "title": "hello!" }'
    assert_equal "[?user_id=1]", last_request.query_string
  end

  test "setting query params on put requests" do
    get '/login'
    put '/testing/1', '{ "title": "hello!" }'
    assert_equal "[?user_id=1]", last_request.query_string
  end

  test "setting query params on delete requests" do
    get '/login'
    delete '/testing'
    assert_equal "[?user_id=1]", last_request.query_string
  end

  test "setting query params on get requests" do
    @test_methods = [:get]
    get '/login'
    get '/testing'
    assert_equal "[?user_id=1]", last_request.query_string
  end

  test "not adding methods when the request method is not filterable" do
    @test_methods = [:post]
    get '/login'
    get '/testing'
    assert_not_equal "[?user_id=1]", last_request.query_string
  end

  test "appending query params to a document" do
    get '/login'
    post '/testing', '{ "title": "hello!" }'
    assert_match /"user_id":1/, last_response.body
  end

  test "handling invalid json" do
    get '/login'
    post '/testing', 'invalid json'
    assert_equal 422, last_response.status
  end
end