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
        [200, {'Content-Length' => request.json.length, 'Content-Type' => 'text/plain'}, request.json]
      },  :collections => [:testing], :filters => [:user_id]
    )
  end

  def test_adding_user_id_query_parameter
    get '/login'
    get '/testing'
    assert_equal "[?user_id=1]", last_request.query_string
  end

  def test_not_overriding_existing_query_parameters
    get '/login'
    get '/testing?[?title=awesome]'
    assert_equal '[?title=awesome][?user_id=1]', URI.decode(last_request.query_string)
  end

  def test_reject_request_if_no_session_var
    get '/testing'
    assert_equal 412, last_response.status
  end

  def test_setting_query_params_on_post
    get '/login'
    post '/testing', '{ "title": "hello!" }'
    assert_equal "[?user_id=1]", last_request.query_string
  end

  def test_setting_query_params_on_put
    get '/login'
    put '/testing/1', '{ "title": "hello!" }'
    assert_equal "[?user_id=1]", last_request.query_string
  end

  def test_setting_query_params_on_delete
    get '/login'
    delete '/testing'
    assert_equal "[?user_id=1]", last_request.query_string
  end

  def test_appending_query_param_to_document
    get '/login'
    post '/testing', '{ "title": "hello!" }'
    assert_match /"user_id":1/, last_response.body
  end
end