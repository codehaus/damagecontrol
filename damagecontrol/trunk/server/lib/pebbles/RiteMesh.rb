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
      Thread.current['parse_tag_value'] = ""
      if input =~ Regexp.new("<#{tag}(.*?)>(.*)<\/#{tag}>", Regexp::MULTILINE)
        attributes[tag] = $1.chomp
        Thread.current['parse_tag_value'] = $2.chomp
      end      
      eval("#{tag} = Thread.current['parse_tag_value']", binding)
      Thread.current['parse_tag_value'] = nil
    end
    
  end
    
end
