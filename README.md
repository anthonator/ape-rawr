# ApeRawr

Ever wanted an easy way to validate your API parameters and spit out clean, developer friendly error messages? Ever notice how there's no good way to do that in Rails?

Enter ApeRawr!

## Contributions

ApeRawr is an amalgamation of two awesome gems: Grape and RocketPants. This gem combines the error handling capabilities of ApeRawr with the parameter validation of Grape into a single cohesive tool used for making API parameter validation easier. The maintainers of RocketPants and Grape deserve most of the credit for this gem. I just provided the glue.

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

### Handling Errors

One of the built in features of ApeRawr is the ability to handle rescuing / controlling exceptions and more importantly to handle mapping exceptions to names, messages and error codes.

This comes in useful when you wish to automatically convert exceptions such as `ActiveRecord::RecordNotFound` (Note: This case is handled already) to a structured bit of data in the response. Namely, it makes it trivial to generate objects that follow the JSON structure of:

```json
{
  "error":             "standard_error_name",
  "error_description": "A translated error message describing what happened."
}
```

It also adds a facilities to make it easy to add extra information to the response.

ApeRawr will also attempt to convert all errors in the controller, defaulting to the `"system"` exception name and message as the error description. We also provide a registry to allow throwing exception from their symbolic name like so:

```ruby
error! :not_found
```

In the controller.

Out of the box, the following exceptions come pre-registered and setup. For each of them, you can either use the error form (`error! :error_key) or you can raise an instance of the exception class like normal.

<table>
  <tr>
    <th>Error Key</th>
    <th>Exception Class</th>
    <th>HTTP Status</th>
    <th>Description</th>
  </tr>
  <tr>
    <td><code>:throttled</code></td>
    <td><code>ApeRawr::Throttled</code></td>
    <td><code>503 Unavailable</code></td>
    <td>The user has hit an api throttled error.</td>
  </tr>
  <tr>
    <td><code>:unauthenticated</code></td>
    <td><code>ApeRawr::Unauthenticated</code></td>
    <td><code>401 Unauthorized</code></td>
    <td>The user doesn't have valid authentication details.</td>
  </tr>
  <tr>
    <td><code>:invalid_version</code></td>
    <td><code>ApeRawr::Invalidversion</code></td>
    <td><code>404 Not Found</code></td>
    <td>An invalid API version was specified.</td>
  </tr>
  <tr>
    <td><code>:not_implemented</code></td>
    <td><code>ApeRawr::NotImplemented</code></td>
    <td><code>503 Unavailable</code></td>
    <td>The specified endpoint is not yet implemented.</td>
  </tr>
  <tr>
    <td><code>:not_found</code></td>
    <td><code>ApeRawr::NotFound</code></td>
    <td><code>404 Not Found</code></td>
    <td>The given resource could not be found.</td>
  </tr>
  <tr>
    <td><code>:invalid_resource</code></td>
    <td><code>ApeRawr::InvalidResource</code></td>
    <td><code>422 Unprocessable Entity</code></td>
    <td>The given resource was invalid.</td>
  </tr>
  <tr>
    <td><code>:bad_request</code></td>
    <td><code>ApeRawr::BadRequest</code></td>
    <td><code>400 Bad Request</code></td>
    <td>The given request was not as expected.</td>
  </tr>
  <tr>
    <td><code>:conflict</code></td>
    <td><code>ApeRawr::Conflict</code></td>
    <td><code>409 Conflict</code></td>
    <td>The resource was a conflict with the existing version.</td>
  </tr>
  <tr>
    <td><code>:forbidden</code></td>
    <td><code>ApeRawr::Forbidden</code></td>
    <td><code>403 Forbidden</code></td>
    <td>The requested action was forbidden.</td>
  </tr>
  <tr>
    <td><code>:presence</td>
    <td><code>ApeRawr::BadRequest</code></td>
    <td><code>400 Bad Request</code></td>
    <td>missing parameter: %{attribute}</td>
  </tr>
  <tr>
    <td><code>:coerce</td>
    <td><code>ApeRawr::BadRequest</code></td>
    <td><code>400 Bad Request</code></td>
    <td>invalid parameter: %{attribute}</td>
  </tr>
  <tr>
    <td><code>:regexp</td>
    <td><code>ApeRawr::BadRequest</code></td>
    <td><code>400 Bad Request</code></td>
    <td>invalid parameter: %{attribute}</td>
  </tr>
</table>

Note that error also excepts a Hash of contextual options, many which will be passed through to the Rails I18N subsystem. E.g:

```ruby
error! :throttled, :max_per_hour => 100
```

Will look up the translation `ape_rawr.errors.throttled` in your I18N files, and call them with `:max_per_hour` as an argument.

Finally, You can use this to also pass custom values to include in the response, e.g:

```ruby
error! :throttled, :metadata => {:code => 123}
```

Will return something similar to:

```json
{
  "error":             "throttled",
  "error_description": "The example error message goes here",
  "code":              123
}
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
