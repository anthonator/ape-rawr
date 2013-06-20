# ApeRawr

Ever wanted an easy way to validate your API paraemters and spit out clean, developer friendly error messages? Ever notice how there's no good way to do that in Rails?

Enter ApeRawr!

## Contributions

ApeRawr is an amalgamation of two awesome gems: Grape and RocketPants. This gem combines the error handling capabilities of RocketPants with the parameter validation of Grape into a single cohesive tool used for making API parameter validation easier. The maintainers of RocketPants and Grape deserve most of the credit for this gem. I just provided the glue.

## Installation

Add this line to your application's Gemfile:

    gem 'ape-rawr'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ape-rawr

## Usage

### Parameter Validation and Coercion
You can define validations and coercion options for you parameters using a params block.

```ruby
params do
  requires :id, type: Integer
  optional :text, type: String, regexp: /^[a-z]+$/
  group :media do
    requires :url
  end
end

def :create
  ...
end
```

When a type is specified an implicit validation is done after the coercion to ensure the output type is the one declared.

Optional parameters can have a default value.

```ruby
params do
  options :color, type: String, default: 'blue'
end
```

Parameters can be nested using `group`. In the above example, this means `params[:media][:url]` is required along with `params[:id]`.

Validations can also be defined for a specific action.

```ruby
params :create do
  ...
end

def create
  ...
end
```

### Custom Validators

```ruby
class AlphaNumeric < Grape::Validations::Validator
  def validate_param!(attr_name, params)
    unless params[attr_name] =~ /^[[:alnum:]]+$/
      error!(:alpha_numeric_error, :attribute => attr_name)
    end
  end
end
```

```ruby
params do
  requires :text, alpha_numeric: true
end
```

You can also create custom classes that take parameters.

```ruby
class Length < Grape::Validations::SingleOptionValidator
  def validate_param!(attr_name, params)
    unless params[attr_name].length <= @option
      error!(:length_error, :attribute => attr_name, :expected_length => @option)
    end
  end
end
```

```ruby
params do
  requires :text, length: 140
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
