# sinatra-my-params
Check for sinatra params, either hard or soft check

Basic usage

```ruby
permitted_params(params, permitted = {}, strong_validation = false)
```

If strong_validation is set to true, method will rise an error; if not it will only ignore that param


```ruby
class Controller 
  include PermitParams

  get "/endpoint" do
    permitted_params = permitted_params(
      params, { name: String }
    )

    ...
  end
end
```

Parameters outside of permitted will be removed

All feedback is welcome. Super early stage

