# sinatra-my-params

Check your input params, both by name and type, with either a soft (drop invalid) or hard (raise) check.

## Method signature

```ruby
permitted_params(params, permitted = {}, strong_validation = false, options = {})
```

- `params` - the incoming params hash (e.g. Sinatra's `params`).
- `permitted` - a hash of `key => spec`, where `spec` is either a bare type (`String`, `Integer`, ...)
  or a richer field spec hash (`{ type: String, required: true, ... }` - see below).
- `strong_validation` - if `true`, an invalid parameter raises `PermitParams::InvalidParameterError`.
  If `false` (default), an invalid parameter is just dropped from the output.
- `options` - global coercion options (`delimiter:`, `separator:`, `integer_precision:`, `shape:`) applied
  to every field unless a field spec overrides them (see [Per-field options](#per-field-options)).

Parameters not listed in `permitted` are always removed, regardless of `strong_validation`.

## Example 1:

```ruby
input = { parameter: 'a string' }

permitted_params(
  input, { parameter: String }
)
```

output
```ruby
{ parameter: 'a string' }
```

## Example 2:

```ruby
input = { parameter: 'a string' }

permitted_params(
  input, { parameter: Integer }
)
```

output
```ruby
{ }
```

## Example 3:
To ignore type

```ruby
input = { parameter: 'a string' }

permitted_params(
  input, { parameter: Any }
)
```

output
```ruby
{ parameter: 'a string' }
```

## Usage in class

```ruby
class Controller
  include PermitParams

  get "/endpoint" do
    safe_params = permitted_params(
      params, { parameter: String }
    )

    ...
  end
end
```

## Permitted params types
  * `Any` (no type check, only name check)
  * `Boolean`
  * `Integer`
  * `Float`
  * `String`
  * `Date`
  * `Time`
  * `DateTime`
  * `Array`
  * `Hash`
  * `TrueClass`
  * `FalseClass`
  * `Shape` (hash shape validation - see [Shape](#shape) below)

`Date`, `Time`, `DateTime`, `Integer` and `Float` parsing caps string input at 128 bytes before handing it
to Ruby's parser, as a defense against resource-exhaustion attacks from very long attacker-controlled input.

## Field spec hash

Every permitted value can be either a bare type (as above) **or** a hash describing a richer contract:

```ruby
permitted_params(input, {
  key => {
    type: String,             # required - any type from the list above
    required: true,           # raise if missing/invalid, regardless of strong_validation
    default: 'fallback',      # used when the param is missing or invalid
    in: %w[a b c],            # value must be one of these, after coercion
    match: /\A[A-Z]+\z/,      # value must match this Regexp (String values only)
    min: 1,                   # numeric lower bound, or minimum length for String/Array/Hash
    max: 10,                  # numeric upper bound, or maximum length for String/Array/Hash
    of: Integer,              # Array only - coerce every element to this type
    shape: { ... },           # Shape only - see below; overrides the global options[:shape]
    delimiter: ';',           # overrides the global options[:delimiter] for this field only
    separator: ':',           # overrides the global options[:separator] for this field only
    integer_precision: 16     # overrides the global options[:integer_precision] for this field only
  }
})
```

Bare types (`{ key: String }`) and field spec hashes (`{ key: { type: String } }`) can be freely mixed
within the same `permitted` hash.

### `required:`

```ruby
permitted_params({}, { email: { type: String, required: true } })
# raises PermitParams::MissingParameterError, "'email' is required"

permitted_params({ email: 'not-an-email' }, { email: { type: String, required: true, match: /@/ } })
# raises PermitParams::InvalidParameterError, "'not-an-email' is not a valid String..."
```

`required:` always raises when unmet, independent of `strong_validation` - it's an explicit,
per-field opt-in, so it wouldn't do anything useful if it deferred to the global lenient default.
`PermitParams::MissingParameterError` is a subclass of `PermitParams::InvalidParameterError`, so
existing `rescue PermitParams::InvalidParameterError` code keeps working unchanged if you don't
care about the distinction between "missing" and "invalid".

### `default:`

```ruby
permitted_params({}, { role: { type: String, default: 'member' } })
# => { role: 'member' }
```

Used whenever the field ends up with no valid value - whether it was never supplied, or supplied
but failed coercion/validation. `default:` takes priority over `required:` (a required field with a
default never raises - the default satisfies it). The default value is used as-is, not re-coerced
or re-validated.

### `in:` (enum)

```ruby
permitted_params({ status: 'archived' }, { status: { type: String, in: %w[draft published] } })
# => {}  (or raises with strong_validation: true)
```

### `match:` (format)

```ruby
permitted_params({ code: 'abc' }, { code: { type: String, match: /\A[A-Z]{3}\d{3}\z/ } })
# => {}
```

### `min:` / `max:`

Applied to the value directly for `Integer`/`Float`, and to `.length` for `String`/`Array`/`Hash`:

```ruby
permitted_params({ age: '10' }, { age: { type: Integer, min: 18 } })
# => {}

permitted_params({ name: 'a' }, { name: { type: String, min: 2 } })
# => {}
```

### `of:` (typed array elements)

```ruby
permitted_params({ ids: '1,2,3' }, { ids: { type: Array, of: Integer } })
# => { ids: [1, 2, 3] }

permitted_params({ ids: '1,x,3' }, { ids: { type: Array, of: Integer } })
# => { ids: [1, 3] }   (invalid elements are dropped, not the whole array)
```

`of:` also works against a param that's already an `Array` (e.g. a JSON body), and can be combined
with `Shape` for an array of nested objects - see [Shape](#shape).

## Per-field options

Any of `delimiter:`, `separator:`, `integer_precision:` and `shape:` can be set per-field inside the
field spec hash, overriding the global `options` 4th argument for that field only. This means
different `Shape`-typed fields can each use their own shape, and different `Array`/`Hash`-typed
fields can each use their own delimiter, in a single `permitted_params` call:

```ruby
permitted_params(input, {
  author: { type: Shape, shape: { name: String } },
  book: { type: Shape, shape: { title: String, year: Integer } },
  tags: { type: Array, delimiter: ';' }
})
```

## Shape

`Shape` validates a nested hash against a declared shape, dropping any keys not present in the
shape:

```ruby
permitted_params(
  { user: { name: 'Ada', age: 32 } },
  { user: { type: Shape, shape: { name: String, age: Integer } } }
)
# => { user: { name: 'Ada', age: 32 } }
```

Combine with `of:` for an array of shapes:

```ruby
permitted_params(
  { items: [{ id: 1, name: 'a' }, { id: 2, name: 'b' }] },
  { items: { type: Array, of: Shape, shape: { id: Integer, name: String } } }
)
# => { items: [{ id: 1, name: 'a' }, { id: 2, name: 'b' }] }
```

An unexpected nested hash, a malformed input, or a missing `shape:` option is always rejected
safely (dropped, or raised with `strong_validation: true`) rather than raising an unhandled
exception. See [tests](https://github.com/mhero/sinatra-my-params/blob/main/spec/permit_params_shape_spec.rb)
for more examples.

## Errors

  * `PermitParams::InvalidParameterError` - raised with `strong_validation: true` when a param
    fails type coercion or a `in:`/`match:`/`min:`/`max:` constraint, or when a `required:` field
    is present but invalid (regardless of `strong_validation`).
  * `PermitParams::MissingParameterError < PermitParams::InvalidParameterError` - raised when a
    `required:` field has no value at all (not present in `params`, or explicitly `nil`) and no
    `default:`.

## Contributing

```
bundle install
bundle exec rake   # runs the rspec suite
```

See [CHANGELOG.md](CHANGELOG.md) for release history and [SECURITY.md](SECURITY.md) to report a
vulnerability.

All feedback is welcome.
