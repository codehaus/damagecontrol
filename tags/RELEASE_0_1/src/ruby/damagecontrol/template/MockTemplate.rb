require 'test/unit'

module DamageControl
  class MockTemplate    

    attr_accessor :expected_to_generate

    def initialize
      @did_generate = false
    end

    def generate(build)
      @did_generate = true
    %{
Hello
From
DamageControl
    }
    end
    
    def file_name
      "trash.txt"
    end

    def verify(test)
      test.assert_equal(expected_to_generate, @did_generate)
    end
  end
end