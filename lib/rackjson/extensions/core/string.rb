class String
  def numeric?
    true if Float(self) rescue false
  end

  def to_number
    if numeric?
      f = to_f
      i = to_i
      f == i ? i : f
    end
  end
end