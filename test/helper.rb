require 'rubygems'
require 'test/unit'
require 'rack'
require 'rack/test'
require 'timecop'
require 'uri'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rackjson'

class Test::Unit::TestCase
end
