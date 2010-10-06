class Array
  def self.wrap(object)
    case object
    when nil
      []
    when self
      object
    else
      [object]
    end
  end
end