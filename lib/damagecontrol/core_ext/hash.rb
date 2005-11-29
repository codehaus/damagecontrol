class Hash
  def deserialize_to_array
    result = []
    self.each do |class_name, values|
      result << deserialize(class_name, values)
    end
    result
  end

private

  # Deserialises an object from a Hash holding attribute values. 
  # Special rules:
  # * "true" and "false" strings are turned into booleans.
  # * "nil" is turned into nil.
  # * Array values are eval'ed to classes and new'ed.
  # * Hash values are turned into a new Hash by combining its
  #   :keys and :values entries (This is handier to POST from forms).
  # * attribute names ending with '_yaml' will have '_yaml' stripped
  #   off and the value will be YAML::load'ed from the original value.
  #
  def deserialize(class_name, attributes)
    object = eval(class_name).new
    attributes.each do |attr_name, attr_value|
      if(attr_value == "true")
        attr_value = true
      elsif(attr_value == "false")
        attr_value = false
      elsif(attr_value == "nil")
        attr_value = nil
      elsif(attr_name =~ /(.*)_yaml/)
        attr_value = YAML::load(attr_value)
        attr_name = $1
      elsif(attr_value.is_a?(Array))
        attr_value = instantiate_array(attr_value)
      elsif(attr_value.is_a?(Hash) && attr_value[:values].is_a?(Array))
        keys = attr_value[:keys]
        values = attr_value[:values]
        attr_value = {}
        keys.each_with_index do |key, i|
          attr_value[key] = values[i]
        end
      end

      setter = "#{attr_name}=".to_sym
      object.__send__(setter, attr_value) rescue nil
    end
    object
  end

  def instantiate_array(array)
    result = array.collect do |cls_name| 
      eval(cls_name).new
    end
  end

end
