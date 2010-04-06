require 'helper'

class ResponseTest < Test::Unit::TestCase
  def test_setting_the_content
    response = Rack::JSON::Response.new("test")
    assert_equal(3, response.to_a.length)
  end

  def test_default_http_status_to_200
    response = Rack::JSON::Response.new("test")
    assert_equal(200, response.to_a[0])
  end

  def test_setting_http_status_code
    response = Rack::JSON::Response.new("test", :status => 422)
    assert_equal(422, response.to_a[0])
  end

  def test_response_body
    response = Rack::JSON::Response.new("test")
    assert_equal(["test"], response.to_a[2])
  end

  def test_setting_the_content_length
    response = Rack::JSON::Response.new("test")
    assert_equal("4", response.to_a[1]["Content-Length"])
  end

  def test_setting_the_content_type
    response = Rack::JSON::Response.new("test")
    assert_equal("text/plain", response.to_a[1]["Content-Type"])
  end

  def test_sending_json
    response = Rack::JSON::Response.new("{'title': 'hello'}")
    assert_equal(["{'title': 'hello'}"], response.to_a[2])
  end

  def test_head_response
    response = Rack::JSON::Response.new("test", :head => true)
    assert_equal([""], response.to_a[2])
    assert_equal("4", response.to_a[1]["Content-Length"])
    assert_equal("text/plain", response.to_a[1]["Content-Type"])
  end
end