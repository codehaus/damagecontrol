require 'erb'

module Pebbles

  module RiteMesh
    def mesh(input, decorator, binding = binding)
      attributes = {}
      parse_tag(input, "title", binding, attributes)
      parse_tag(input, "body", binding, attributes)
      result = ERB.new(decorator).result(binding)
      result.gsub!(/<body.*>/, "<body#{attributes['body']}>")
      result
    end
    
    private
    
    def parse_tag(input, tag, binding, attributes)
      value = ""
      if input =~ Regexp.new("<#{tag}(.*?)>(.*)<\/#{tag}>", Regexp::MULTILINE)
        attributes[tag] = $1.chomp
        value = $2.chomp
      end
      eval("#{tag} = #{value.inspect}", binding)
    end
  end
    
end