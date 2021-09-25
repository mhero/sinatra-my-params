# frozen_string_literal: true

require 'test/unit'
require 'permit_params'
require 'rspec'
require 'rack/test'

include PermitParams

describe 'exceptions' do
  before do
    class TestClass; end
  end

  it 'should raise error when at least one param is invalid' do
    input = { param_1: 'a' }
    expect  do
      permitted_params(input, { param_1: Integer }, true)
    end.to raise_error(InvalidParameterError, "'a' is not a valid Integer")
  end

  it 'should return a string when a pemitted is string' do
    input = { param_1: 'a string' }
    expect(input).to eq permitted_params(input, { param_1: String })
  end

  it 'should return a float when a pemitted is float' do
    input = { param_1: 10.0 }
    expect(input).to eq permitted_params(input, { param_1: Float })
  end

  it 'should return a date when a pemitted is date' do
    input = { param_1: Date.new }
    expect(input).to eq permitted_params(input, { param_1: Date })
  end

  it 'should return a time when a pemitted is time' do
    input = { param_1: Time.new }
    expect(input).to eq permitted_params(input, { param_1: Time })
  end

  it 'should return an integer when a pemitted is integer' do
    input = { param_1: 1 }
    expect(input).to eq permitted_params(input, { param_1: Integer })
  end

  it 'should return an integer when a pemitted can be cast into integer' do
    input = { param_1: '1' }
    output = { param_1: 1 }
    expect(output).to eq permitted_params(input, { param_1: Integer })
  end

  it 'should return a false(boolean) when a pemitted is boolean' do
    input = { param_1: 'false' }
    output = { param_1: false }
    expect(output).to eq permitted_params(input, { param_1: Boolean })
  end

  it 'should return a true(boolean) when a pemitted is boolean' do
    input = { param_1: 'true' }
    output = { param_1: true }
    expect(output).to eq permitted_params(input, { param_1: Boolean })
  end

  it 'should return an array when a pemitted is array' do
    input = { param_1: [1, 2] }
    expect(input).to eq permitted_params(input, { param_1: Array })
  end

  it 'should return an array when a pemitted is array' do
    input = { param_1: '1, 2' }
    output = { param_1: %w[1 2] }
    expect(output).to eq permitted_params(input, { param_1: Array })
  end

  it 'should return a hash when a pemitted is hash' do
    input = { param_1: 'a: 1, b: 2' }
    output = { param_1: { 'a' => '1', 'b' => '2' } }
    expect(output).to eq permitted_params(input, { param_1: Hash })
  end

  it 'should return a hash when a pemitted is hash' do
    input = { param_1: { a: 1 } }
    expect(input).to eq permitted_params(input, { param_1: Hash })
  end

  it 'should return a hash when a pemitted is hash' do
    input = { param_1: { a: 1 } }
    expect(input).to eq permitted_params(input, { param_1: Hash })
  end

  it 'should return a hash when a pemitted is hash' do
    input = { param_1: { "a": 1 } }
    expect(input).to eq permitted_params(input, { param_1: Hash })
  end

  it 'should return a several types for several inputs' do
    input = { number: 1, string: 'string', bol: 'true', array: [1, 2], hsh: { a: 3 } }
    output = { number: 1, string: 'string', bol: true, array: [1, 2], hsh: { a: 3 } }
    expect(output).to eq permitted_params(
      input,
      {
        number: Integer,
        string: String,
        bol: Boolean,
        array: Array,
        hsh: Hash
      }
    )
  end

  it 'returns the paramter without casting if Any' do
    input = { param_1: '1' }
    output = { param_1: '1' }
    expect(output).to eq permitted_params(input, { param_1: Any })

    input = { param_1: TestClass.new }
    expect(input).to eq permitted_params(input, { param_1: Any })
  end

  it 'should remove a string when a pemitted is integer' do
    input = { param_1: 'a string' }
    output = {}
    expect(output).to eq permitted_params(input, { param_1: Integer })
  end

  it 'should allow all params when no restriction is given' do
    input = { param_1: 'a string' }
    expect(input).to eq permitted_params(input)
  end
end
