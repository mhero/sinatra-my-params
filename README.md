# sinatra-my-params
Check for sinatra params, either hard or soft check

Basic ussage

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

