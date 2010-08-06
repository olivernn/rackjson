require 'helper'

class ResponseTest < Test::Unit::TestCase
  def test_setting_the_content
    response = Rack::JSON::Response.new("test")
    assert_equal(3, response.to_a.length)
  end

  def test_default_http_status_to_200
    response = Rack::JSON::Response.new("test")
    assert_equal(200, response.status)
  end

  def test_setting_http_status_code
    response = Rack::JSON::Response.new("test", :status => 422)
    assert_equal(422, response.status)
  end

  def test_response_body
    response = Rack::JSON::Response.new("test")
    assert_equal("test", response.body)
  end

  def test_setting_the_content_length
    response = Rack::JSON::Response.new("test")
    assert_equal("4", response.headers["Content-Length"])
  end

  def test_setting_the_content_type
    response = Rack::JSON::Response.new("test")
    assert_equal("text/plain", response.headers["Content-Type"])
  end

  test "sending hash" do
    response = Rack::JSON::Response.new({:title => 'Hello'})
    assert_equal(JSON.generate({:title => 'Hello'}), response.body)
  end

  def test_head_response
    response = Rack::JSON::Response.new("test", :head => true)
    assert_equal([""], response.to_a[2])
    assert_equal("4", response.to_a[1]["Content-Length"])
    assert_equal("text/plain", response.headers["Content-Type"])
  end
end