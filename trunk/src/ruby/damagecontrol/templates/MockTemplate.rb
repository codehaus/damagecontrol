module DamageControl
  class MockTemplate    

    attr_accessor :expected_to_generate

    def initialize
      @did_generate = false
    end

    def generate(build_result)
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

    def verify
      assert_equal(@did_generate, expected_to_generate)
    end
  end
end