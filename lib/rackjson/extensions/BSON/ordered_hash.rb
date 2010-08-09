class BSON::OrderedHash
  def to_h
    inject({}) { |acc, element| k,v = element; acc[k] = (if v.class == BSON::OrderedHash then v.to_h else v end); acc }
  end

  def to_json
    to_h.to_json
  end
end