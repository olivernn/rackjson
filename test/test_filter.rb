require 'helper'
require 'uri'

class ResourceTest < Test::Unit::TestCase
  include Rack::Test::Methods
  include Rack::Utils

  def app
    Rack::Session::Cookie.new(
      Rack::JSON::Filter.new lambda { |env|
        env['rack.session'] = {}
        env['rack.session']['user_id'] = 1
        [200, {'Content-Length' => '2', 'Content-Type' => 'text/plain'}, "OK"]
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

  def test_not_setting_query_string_if_no_session_var
    get '/testing'
    puts last_request.query_string
    assert_equal "", last_request.query_string
  end

  def test_not_overriding_existing_query_parameters_if_no_session_var
    get '/testing?[?title=awesome]'
    assert_equal '[?title=awesome]', URI.decode(last_request.query_string)
  end
end