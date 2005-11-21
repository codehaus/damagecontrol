module FerretConfig
  include Ferret::Document
  
  class SourceCodeTokenizer < Ferret::Analysis::RegExpTokenizer
  protected
    # Collects only characters which satisfy the regular expression
    # _/[[:alpha:]_@$?!]+/
    #
    def token_re()
      /[[:alpha:]_@$?!]+/
    end
  end

  class SourceCodeAnalyzer < Ferret::Analysis::StopAnalyzer
    # An array containing some common ruby words that are not usually useful
    # for searching.
    
    # http://www.rubycentral.com/book/language.html
    RUBY_STOP_WORDS = [
      "__FILE__", "and", "def", "end", "in", "or", "self", "unless",
      "__LINE__", "begin", "defined?", "ensure", "module", "redo", "super", "until",
      "BEGIN", "break", "do", "false", "next", "rescue", "then", "when",
      "END", "case", "else", "for", "nil", "retry", "true", "while",
      "alias", "class", "elsif", "if", "not", "return", "undef", "yield"
    ]
    
    # http://java.sun.com/docs/books/tutorial/java/nutsandbolts/_keywords.html
    JAVA_STOP_WORDS = [
      "abstract", "continue", "for", "new", "switch", "assert", "default", "goto", "package", "synchronized",
      "boolean", "do", "if", "private", "this", "break", "double", "implements", "protected", "throw", "byte", 
      "else", "import", "public", "throws", "case", "enum", "instanceof", "return", "transient", "catch",
      "extends", "int", "short", "try", "char", "final", "interface", "static", "void", "class", "finally",
      "long", "strictfp", "volatile", "const", "float", "native", "super", "while"
    ]
    WORDS = Hash.new([])
    WORDS.merge!({
      ".rb"   => RUBY_STOP_WORDS,
      ".java" => JAVA_STOP_WORDS
    })

    # Builds an analyzer which removes words in the provided array.
    def initialize(extension)
      @stop_words = WORDS[extension]
    end

    # Filters CodeTokenizer with StopFilter.
    def token_stream(field, string)
      return Ferret::Analysis::StopFilter.new(SourceCodeTokenizer.new(string), @stop_words)
    end
  end
  
end
