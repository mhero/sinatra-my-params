require 'test/unit'
require 'permit_params'
require 'rspec'
require 'rack/test'

class PermitParamsTest < Test::Unit::TestCase
  include PermitParams

  def test_pemit_string
    input = { param_1: "hola" }
    output = { param_1: "hola" }
    assert_equal output, permitted_params( input, { param_1: String } )
  end

  def test_permit_integer
    input = { param_1: 1 }
    output = { param_1: 1 }
    assert_equal output, permitted_params( input, { param_1: Integer } )
  end

  def test_remove_integer
    input = { param_1: "a"}
    output = {}
    assert_equal output, permitted_params( input, { param_1: Integer } )
  end

  describe 'exceptions' do
    describe 'raise' do
      it 'should raise error when at least one param is invalid' do
        input = { param_1: "a" }
        expect(permitted_params( input, { param_1: Integer }, true )).to raise_error InvalidParameterError
      end
    end
  end
end
