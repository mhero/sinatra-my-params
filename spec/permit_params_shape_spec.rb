# frozen_string_literal: true

require 'test/unit'
require 'permit_params'
require 'rspec'
require 'rack/test'

include PermitParams

describe 'shape behaviours' do
  it 'should return a hash when a pemitted is of shape' do
    input = { param: { a: 1, b: 2 } }
    expect(input).to eq permitted_params(
      input,
      { param: Shape },
      false,
      { shape: { a: Integer, b: Integer } }
    )
  end

  it 'should return a hash when a pemitted is of Integer shape(deep)' do
    input = { param: { a: { b: 2 } } }
    expect(input).to eq permitted_params(
      input,
      { param: Shape },
      false,
      { shape: { a: { b: Integer } } }
    )
  end

  it 'should return a hash when a pemitted is of Array shape(deep)' do
    input = { param: { a: { b: [1, 2] } } }
    expect(input).to eq permitted_params(
      input,
      { param: Shape },
      false,
      { shape: { a: { b: Array } } }
    )
  end

  it 'should return a empty object when a pemitted is shape not defined' do
    input = { param: { a: 1, b: 2 } }
    expect({}).to eq permitted_params(
      input,
      { param: Shape },
      false,
      { shape: { a: Integer } }
    )
  end
end
