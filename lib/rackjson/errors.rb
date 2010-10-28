module Rack::JSON
  class NoFilterError < ArgumentError ; end
  class DataTypeError < TypeError ; end
  class DocumentFormatError < ArgumentError ; end
  class UnrecognisedPathTypeError < StandardError ; end
  class BodyFormatError < ArgumentError ; end
end