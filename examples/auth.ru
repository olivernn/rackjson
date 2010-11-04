require 'rubygems'
require 'rack'
require 'rackjson'

class Auth

  def initialize(app)
    @app = app
  end

  def call(env)
    @env = env
    @auth = Rack::Auth::Basic::Request.new(@env)
    @auth.provided? || @env['rack.session']['user_id'] ? authorize! : unauthorized!
  end

  def authorize!
    if @auth.credentials == ["oliver", "pass"]
      @env['rack.session']["user_id"] = "oliver"
      authorized
    elsif @auth.credentials == ["bob", "pass"]
      @env['rack.session']["user_id"] = "bob"
      authorized
    else
      unauthorized!
    end
  end

  def authorized
    status, headers, response = @app.call(@env)
    [status, headers, response]
  end

  def unauthorized!
    @env['rack.session']['user_id'] = nil
    [
      401,
      { 
        'WWW-Authenticate' => "Basic realm='localhost'",
        'Content-Length' => '22',
        'Content-Type' => 'text/plain'
      }, 
      "Authorization Required"
    ]
  end
end




use Rack::Session::Cookie
use Auth

private_resource :collections => [:notes], :filters => [:user_id], :db => Mongo::Connection.new.db("test")
public_resource :collections => [:posts], :filters => [:user_id], :db => Mongo::Connection.new.db("test")

run lambda { |env| 
  [404, {'Content-Length' => '9', 'Content-Type' => 'text/plain'}, "Not Found"]
}