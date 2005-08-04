require 'test/unit'
require 'astray'

class AstrayTest < Test::Unit::TestCase
  def test_should_go_astray
    astray = Astray.new
    rest = astray.go % 4
    assert (rest == 0) || (rest == 1)
  end
end
