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
    output = { param_1: "a string" }
    expect(output).to eq permitted_params(input, { param_1: String })
  end

  it "should return an integer when a pemitted is integer" do
    input = { param_1: 1 }
    output = { param_1: 1 }
    expect(output).to eq permitted_params(input, { param_1: Integer })
  end

  it "should remove a string when a pemitted is integer" do
    input = { param_1: "a string" }
    output = {}
    expect(output).to eq permitted_params(input, { param_1: Integer })
  end

  it "should allow all params when no restriction is given" do
    input = { param_1: "a string" }
    output = { param_1: "a string" }
    expect(output).to eq permitted_params(input)
  end
end

