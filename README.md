# sinatra-my-params
Check for your inputs params, both by name and type, either hard or soft check

## Method signature

```ruby
permitted_params(params, permitted = {}, strong_validation = false)
```

If strong_validation is set to true and the input parameter is not valid, method will rise an error. 
If strong_validation is set to false and the input parameter is not valid, the parameter will be just ignored(removed).
Parameters outside of permitted ones will be removed.

## Example 1:

```ruby
input = { parameter: 'a string' }

permitted_params(
  input, { parameter: String }
)
```

output
```
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
```
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
```
{ parameter: 'a string' }
```

## Usage in class

```ruby
class Controller 
  include PermitParams

  get "/endpoint" do
    permitted_params = permitted_params(
      params, { parameter: String }
    )

    ...
  end
end
```

## Permitted params types
  * Any(no type check, only name check)
  * Boolean
  * Integer
  * Float 
  * String,
  * Date
  * Time
  * DateTime
  * Array
  * Hash
  * TrueClass 
  * FalseClass
  * Shape(experimental hash shape [more info in tests](https://github.com/mhero/sinatra-my-params/blob/main/spec/permit_params_shape_spec.rb))

All feedback is welcome.

