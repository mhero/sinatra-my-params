# frozen_string_literal: true

require 'test/unit'
require 'permit_params'
require 'rspec'
require 'rack/test'

include PermitParams

describe 'behaviours' do
  it 'should raise error when at least one param is invalid' do
    input = { param: 'a' }
    expect  do
      permitted_params(input, { param: Integer }, true)
    end.to raise_error(InvalidParameterError, "'a' is not a valid Integer")
  end

  it 'should allow all params when no restriction is given' do
    input = { param: 'a string' }
    expect(input).to eq permitted_params(input)
  end

  it 'should remove a string when permitted param is integer' do
    input = { param: 'a string' }
    output = {}
    expect(output).to eq permitted_params(input, { param: Integer })
  end

  it 'should return an integer when permitted param is integer' do
    input = { param: 1 }
    expect(input).to eq permitted_params(input, { param: Integer })
  end

  it 'should return an integer when permitted param can be cast into integer' do
    input = { param: '1' }
    output = { param: 1 }
    expect(output).to eq permitted_params(input, { param: Integer })
  end

  it 'should return a string when permitted param is string' do
    input = { param: 'a string' }
    expect(input).to eq permitted_params(input, { param: String })
  end

  it 'should return a float when permitted param is float' do
    input = { param: 10.0 }
    expect(input).to eq permitted_params(input, { param: Float })
  end

  it 'should return a date when permitted param is date' do
    input = { param: Date.new }
    expect(input).to eq permitted_params(input, { param: Date })
  end

  it 'should return a time when permitted param is time' do
    input = { param: Time.new }
    expect(input).to eq permitted_params(input, { param: Time })
  end

  it 'should return a false(boolean) when permitted param is boolean' do
    input = { param: 'false' }
    output = { param: false }
    expect(output).to eq permitted_params(input, { param: Boolean })
  end

  it 'should return a true(boolean) when permitted param is boolean' do
    input = { param: 'true' }
    output = { param: true }
    expect(output).to eq permitted_params(input, { param: Boolean })
  end

  it 'should return an array when permitted param is array' do
    input = { param: [1, 2] }
    expect(input).to eq permitted_params(input, { param: Array })
  end

  it 'should return an array when permitted param is array' do
    input = { param: '1, 2' }
    output = { param: %w[1 2] }
    expect(output).to eq permitted_params(input, { param: Array })
  end

  it 'should return an array when permitted param is array' do
    input = { param: '1; 2' }
    output = { param: %w[1 2] }
    expect(output).to eq permitted_params(input, { param: Array }, false, { delimiter: ';' })
  end

  it 'should return an empty hash when permitted param is array with wrong delimiter' do
    input = { param: '1; 2' }
    output = {}
    expect(output).to eq permitted_params(input, { param: Array }, false, { delimiter: ',' })
  end

  it 'should return a hash when permitted param is hash' do
    input = { param: 'a: 1, b: 2' }
    output = { param: { 'a' => '1', 'b' => '2' } }
    expect(output).to eq permitted_params(input, { param: Hash })
  end

  it 'should return a hash when permitted param is hash' do
    input = { param: 'a: 1; b: 2' }
    output = { param: { 'a' => '1', 'b' => '2' } }
    expect(output).to eq permitted_params(input, { param: Hash }, false, { delimiter: ';' })
  end

  it 'should return an empty hash when permitted param is hash with wrong separator' do
    input = { param: 'a: 1; b: 2' }
    output = {}
    expect(output).to eq permitted_params(input, { param: Hash }, false, { separator: '.' })
  end

  it 'should return an empty hash when permitted param is hash with wrong delimiter' do
    input = { param: 'a: 1; b: 2' }
    output = {}
    expect(output).to eq permitted_params(input, { param: Hash }, false, { delimiter: ',' })
  end

  it 'should return a hash when permitted param is hash' do
    input = { param: { a: 1 } }
    expect(input).to eq permitted_params(input, { param: Hash })
  end

  it 'should return a hash when permitted param is hash' do
    input = { param: { a: { b: 1 } } }
    expect(input).to eq permitted_params(input, { param: Hash })
  end

  it 'should return a hash when permitted param is hash' do
    input = { param: { "a": 1 } }
    expect(input).to eq permitted_params(input, { param: Hash })
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
    class TestClass
      attr_accessor :some_attribute

      def initialize(some_attribute: nil)
        @some_attribute = some_attribute
      end
    end

    input = { param: '1' }
    output = { param: '1' }
    expect(output).to eq permitted_params(input, { param: Any })

    input = {
      param: TestClass.new(some_attribute: 'a string')
    }
    output = permitted_params(input, { param: Any })
    expect(input[:param].some_attribute).to eq output[:param].some_attribute

    input = {
      param: TestClass.new(some_attribute: 1),
      antoher_param: 2
    }
    output = permitted_params(input, { param: Any })
    expect(input[:param].some_attribute).to eq output[:param].some_attribute
  end
end
