require "test/unit"
require "permit_params"
require "rspec"
require "rack/test"

include PermitParams

describe "exceptions" do
  it "should raise error when at least one param is invalid" do
    input = { param_1: "a" }
    expect{
      permitted_params(input, { param_1: Integer }, true)
    }.to raise_error(InvalidParameterError, "'a' is not a valid Integer") 
  end

  it "should return a string when a pemitted is string" do
    input = { param_1: "a string" }
    expect(input).to eq permitted_params(input, { param_1: String })
  end

  it "should return a float when a pemitted is float" do
    input = { param_1: 10.0 }
    expect(input).to eq permitted_params(input, { param_1: Float })
  end

  it "should return a date when a pemitted is date" do
    input = { param_1: Date.new }
    expect(input).to eq permitted_params(input, { param_1: Date })
  end

  it "should return a time when a pemitted is time" do
    input = { param_1: Time.new }
    expect(input).to eq permitted_params(input, { param_1: Time })
  end

  it "should return an integer when a pemitted is integer" do
    input = { param_1: 1 }
    expect(input).to eq permitted_params(input, { param_1: Integer })
  end

  it "should remove a string when a pemitted is integer" do
    input = { param_1: "a string" }
    output = {}
    expect(output).to eq permitted_params(input, { param_1: Integer })
  end

  it "should allow all params when no restriction is given" do
    input = { param_1: "a string" }
    expect(input).to eq permitted_params(input)
  end
end

