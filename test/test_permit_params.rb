require 'test/unit'
require 'permit_params'

class PermitParamsTest < Test::Unit::TestCase
  include PermitParams

  def test_pemit_string
    input = { param_1: "hola" }
    output = { param_1: "hola" }
    assert_equal output, permitted_params( input, { param_1: String } )
  end
end
