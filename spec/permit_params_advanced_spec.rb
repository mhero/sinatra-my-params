# frozen_string_literal: true

require 'permit_params'
require 'rspec'

describe PermitParams do
  include PermitParams

  # -- required: ------------------------------------------------------

  describe 'required:' do
    it 'raises MissingParameterError when a required param is absent' do
      expect do
        permitted_params({}, { email: { type: String, required: true } })
      end.to raise_error(PermitParams::MissingParameterError, "'email' is required")
    end

    it 'raises MissingParameterError when a required param is explicitly nil' do
      expect do
        permitted_params({ email: nil }, { email: { type: String, required: true } })
      end.to raise_error(PermitParams::MissingParameterError, "'email' is required")
    end

    it 'raises InvalidParameterError (not MissingParameterError) when present but invalid, even with strong_validation false' do
      expect do
        permitted_params({ age: 'not a number' }, { age: { type: Integer, required: true } })
      end.to raise_error(PermitParams::InvalidParameterError, "'not a number' is not a valid Integer")
    end

    it 'does not raise when a required param is present and valid' do
      output = permitted_params({ email: 'a@b.com' }, { email: { type: String, required: true } })
      expect(output).to eq(email: 'a@b.com')
    end

    it 'is a no-op for optional params left unspecified (backward compatible default)' do
      output = permitted_params({}, { nickname: String })
      expect(output).to eq({})
    end

    it 'MissingParameterError is also an InvalidParameterError, so old rescue clauses still catch it' do
      expect(PermitParams::MissingParameterError.ancestors).to include(PermitParams::InvalidParameterError)
    end
  end

  # -- default: ---------------------------------------------------------

  describe 'default:' do
    it 'fills in the default when the param is absent' do
      output = permitted_params({}, { role: { type: String, default: 'member' } })
      expect(output).to eq(role: 'member')
    end

    it 'fills in the default when the param fails coercion' do
      output = permitted_params({ limit: 'lots' }, { limit: { type: Integer, default: 10 } })
      expect(output).to eq(limit: 10)
    end

    it 'uses the given value instead of the default when valid' do
      output = permitted_params({ limit: '25' }, { limit: { type: Integer, default: 10 } })
      expect(output).to eq(limit: 25)
    end

    it 'default takes priority over required (no error raised)' do
      output = permitted_params({}, { role: { type: String, required: true, default: 'member' } })
      expect(output).to eq(role: 'member')
    end
  end

  # -- in: (enum) ---------------------------------------------------------

  describe 'in:' do
    let(:permitted) { { status: { type: String, in: %w[draft published] } } }

    it 'keeps a value that is in the allowed list' do
      output = permitted_params({ status: 'draft' }, permitted)
      expect(output).to eq(status: 'draft')
    end

    it 'drops a value that is not in the allowed list (lenient)' do
      output = permitted_params({ status: 'deleted' }, permitted)
      expect(output).to eq({})
    end

    it 'raises with strong_validation when value is not in the allowed list' do
      expect do
        permitted_params({ status: 'deleted' }, permitted, true)
      end.to raise_error(PermitParams::InvalidParameterError, "'deleted' is not a valid String (must be one of [\"draft\", \"published\"])")
    end
  end

  # -- match: (regex) ------------------------------------------------------

  describe 'match:' do
    let(:permitted) { { code: { type: String, match: /\A[A-Z]{3}\d{3}\z/ } } }

    it 'keeps a value that matches the format' do
      output = permitted_params({ code: 'ABC123' }, permitted)
      expect(output).to eq(code: 'ABC123')
    end

    it 'drops a value that does not match the format (lenient)' do
      output = permitted_params({ code: 'nope' }, permitted)
      expect(output).to eq({})
    end

    it 'raises with strong_validation when value does not match the format' do
      expect do
        permitted_params({ code: 'nope' }, permitted, true)
      end.to raise_error(PermitParams::InvalidParameterError)
    end
  end

  # -- min: / max: ----------------------------------------------------------

  describe 'min: / max:' do
    it 'keeps a numeric value within bounds' do
      output = permitted_params({ age: '25' }, { age: { type: Integer, min: 18, max: 65 } })
      expect(output).to eq(age: 25)
    end

    it 'drops a numeric value below the minimum' do
      output = permitted_params({ age: '10' }, { age: { type: Integer, min: 18 } })
      expect(output).to eq({})
    end

    it 'drops a numeric value above the maximum' do
      output = permitted_params({ age: '99' }, { age: { type: Integer, max: 65 } })
      expect(output).to eq({})
    end

    it 'applies min:/max: to string length' do
      output = permitted_params({ name: 'a' }, { name: { type: String, min: 2 } })
      expect(output).to eq({})
    end

    it 'applies min:/max: to array length' do
      output = permitted_params({ tags: %w[a b] }, { tags: { type: Array, max: 1 } })
      expect(output).to eq({})
    end
  end

  # -- of: (typed array elements) --------------------------------------------

  describe 'of:' do
    it 'coerces each delimited element to the given type' do
      output = permitted_params({ ids: '1,2,3' }, { ids: { type: Array, of: Integer } })
      expect(output).to eq(ids: [1, 2, 3])
    end

    it 'coerces each element of an already-Array param (e.g. JSON body)' do
      output = permitted_params({ ids: %w[1 2 3] }, { ids: { type: Array, of: Integer } })
      expect(output).to eq(ids: [1, 2, 3])
    end

    it 'drops individual invalid elements (lenient)' do
      output = permitted_params({ ids: '1,x,3' }, { ids: { type: Array, of: Integer } })
      expect(output).to eq(ids: [1, 3])
    end

    it 'raises with strong_validation, preserving the precise inner element message' do
      expect do
        permitted_params({ ids: '1,x,3' }, { ids: { type: Array, of: Integer } }, true)
      end.to raise_error(PermitParams::InvalidParameterError, "'x' is not a valid Integer")
    end

    it 'supports of: Shape for an array of nested objects' do
      permitted = { items: { type: Array, of: PermitParams::Shape, shape: { id: Integer, name: String } } }
      input = { items: [{ id: 1, name: 'a' }, { id: 2, name: 'b' }] }
      output = permitted_params(input, permitted)
      expect(output).to eq(items: [{ id: 1, name: 'a' }, { id: 2, name: 'b' }])
    end

    it 'drops array elements whose shape does not match' do
      permitted = { items: { type: Array, of: PermitParams::Shape, shape: { id: Integer } } }
      input = { items: [{ id: 1 }, { id: 'not an integer' }] }
      output = permitted_params(input, permitted)
      expect(output).to eq(items: [{ id: 1 }])
    end
  end

  # -- per-field shape:/delimiter:/separator:/integer_precision: -------------

  describe 'per-field options override the global options hash' do
    it 'lets two different Shape params use two different shapes at once' do
      permitted = {
        author: { type: PermitParams::Shape, shape: { name: String } },
        book: { type: PermitParams::Shape, shape: { title: String, year: Integer } }
      }
      input = { author: { name: 'Ada' }, book: { title: 'Notes', year: 1843 } }

      output = permitted_params(input, permitted)
      expect(output).to eq(author: { name: 'Ada' }, book: { title: 'Notes', year: 1843 })
    end

    it 'falls back to the global options hash shape: when a field does not override it' do
      permitted = { legacy: PermitParams::Shape }
      output = permitted_params({ legacy: { a: 1 } }, permitted, false, shape: { a: Integer })
      expect(output).to eq(legacy: { a: 1 })
    end

    it 'lets a field override the global delimiter' do
      permitted = { tags: { type: Array, delimiter: ';' } }
      output = permitted_params({ tags: '1; 2' }, permitted, false, delimiter: ',')
      expect(output).to eq(tags: %w[1 2])
    end
  end

  # -- combinations -----------------------------------------------------------

  describe 'combined real-world example' do
    it 'validates a small "create user" style payload in one call' do
      permitted = {
        email: { type: String, required: true, match: /\A[^@\s]+@[^@\s]+\z/ },
        role: { type: String, in: %w[member admin], default: 'member' },
        age: { type: Integer, min: 13 },
        tags: { type: Array, of: String, max: 5 }
      }

      output = permitted_params(
        { email: 'a@b.com', age: '30', tags: 'ruby,sinatra' },
        permitted
      )

      expect(output).to eq(
        email: 'a@b.com',
        role: 'member',
        age: 30,
        tags: %w[ruby sinatra]
      )
    end
  end
end
