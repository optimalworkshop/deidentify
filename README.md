# Deidentify

Deidentify is a gem design to allow for easy removal of sensitive data.

It defines a DSL that will allow you to choose which fields should be deidentified. It will then replace the specified database columns with a varity of deidentified values.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'deidentify'
```

And then execute

```
$ bundle install
```

Or install if yourself as:

```
$ gem install deidentify
```

## Usage

Include the deidentify module into you chosen model and add the deidentification DSL.

```ruby
class Person < ApplicationRecord
  include Deidentify

  deidentify :name, method: :replace, new_value: "deidentified"
  deidentify :age, method: :delete
end
```

Then simply call

```ruby
person = Person.find(id)
person.deidentify!
```

This will deidentify the person according to your configuration.

### Recursive Deidentification

This gem allows you to deidentify all data associated with a single object(mostly likely a single user). It does this by traversing associations to propagate the deidentify call.

```ruby
class Person < ApplicationRecord
  include Deidentify

  belongs_to :organisation
  has_many :projects

  deidentify :name, method: :replace, new_value: "deidentified"

  deidentify_associations :organisation, :projects
end
```

Then calling

```ruby
person = Person.find(id)
person.deidentify!
```

will deidentify the person, the organisation they belong to and their projects. It will use the deidentification configuration defined in each class to determine which fields to change.

### Callbacks

You can specify callbacks for the deidentify method.

```ruby
class Person < ApplicationRecord
  include Deidentify

  deidentify :name, method: :replace, new_value: "deidentified"

  before_deidentify do
    delete_file_from_external_store
    send_deletion_request_to_third_party
  end
end
```

## Deidentification Methods
### Delete

This will delete the value in the field and replace it with `nil`.

```ruby
deidentify :email, method: :delete
```

### Replace

This will replace the value with the provided value.

```ruby
deidentify :age, method: :replace, new_value: -1
```
There is a keep nil option that will determine if nils are replaced. By default this is set to `true` which means `nil` will not be replaced with the `new_value`. Setting this to false will mean that `nil` will be replaced with the `new_value`.

```ruby
deidentify :age, method: :replace, new_value: -1, keep_nil: false
```

### Hash

This will replace a string with a hashed version

```ruby
deidentify :name, method: :hash
```

There is a length option that will set the length of the hash.

```ruby
deidentify :name, method: :hash, length: 20
```

NOTE: This uses the SHA256 algorithm to hash. Truncating the length of this shouldn't reduce the security of the hashed value but it will increase the chance of collisions.

### Hash Email

This will replace an email with a hashed version. This will hash the name and domain seperately creating a value of the format `hash@hash`.

```ruby
deidentify :email, method: :hash_email
```

There is a length option that will set the maximum length of the hashed email. NOTE: this can produce emails shorter than the length provided.

```ruby
deidentify :name, method: :hash_email, length: 20
```

NOTE: This also uses SHA256(see hash).

### Hash Url

This will replace a url with a hashed version. This will hash the host, path, query and fragment strings seperately creating a value of the format `https://host/path?query#fragment`.

```ruby
deidentify :url, method: :hash_url
```

There is a length option that will set the maximum length of the hashed url. NOTE: this can produce urls shorter than the length provided.

```ruby
deidentify :url, method: :hash_url, length: 20
```

NOTE: This also uses SHA256(see hash).

### Delocalize IP

This will replace an IP address with its network address turning the last bits to 0s depending on the network mask (by default 24 bits for IPv4 and 48 bits for IPv6).

```ruby
deidentify :ip, method: :delocalize_ip
```

The length of the mask can be provided as parameter

```ruby
deidentify :ip, method: :delocalize_ip, mask_length: 16
```

### Lambda

You can pass a custom lambda as the deidentification method.

```ruby
deidentify :email, method: -> (person) { "deidentified@#{person.email.split("@").last}" }
```

### Keep

You can opt to leave a value untouched.

```ruby
deidentify :age, method: :keep
```

NOTE: You get the same behaviour by simply not specifing a deidentification method for a field.

`Keep` is designed so that it is possible to mark a field as not containing sensitive data. That makes it obvious which fields have been purposely not changed and which have been missed during development.

## Secret Configuration

For the hashing deidenitification methods you can configure this gem to take a secret which will be used to salt the hashed values.
Do this by creating this file `config/initializers/deidentify.rb`

```ruby
Deidentify.configure do |config|
  config.salt = # Your secret value
end
```

## Scope Configuration

It's possible to pass a scope into the configuration.

```ruby
Deidentify.configure do |config|
  config.scope = ->(klass_or_association) { klass_or_association.where(deidentified_at: nil) }
end
```
This scope will limit what records will be deidentified.

So in this example it will not deidentify records that have already been marked as deidentified.

## Generator

This gem comes with a generator that will generate a deidentification policy module for a model. By calling

```
$ rails generate deidentify:configure_for Person
```

you will generate a module in `app/concerns/deidentify/` which will contain all columns of that model.

```ruby
module Deidentify::PersonPolicy
  extend ActiveSupport::Concern
  include Deidentify

  included do
    deidentify :name, method: :keep
    deidentify :age, method: :keep
  end
end
```

NOTE: This will always default to `keep`, you will need to update to other methods manually.

It will also include this module in the model directly after the class declaration.

```ruby
class Person < ApplicationRecord
  include Deidentify::PersonPolicy
  ...
end
```

### Namespaces

This generator will also work with namespaces.

```
$ rails generate deidentify::configure_for Billing::Payment
```

This will generate the module in `app/concerns/deidentify/billing/`

```ruby
module Deidentify::Billing::PaymentPolicy
  ...
end
```

And will add the module in the correct class

```ruby
class Billing::Payment < ApplicationRecord
  include Deidentify::Billing::PaymentPolicy
  ...
end
```

### Specifing the file path

You can specify a file path if your path doesn't match your namespace.
For example if you have a model `Payment` which is found in `app/models/billing/payment.rb`

```
$ rails generate deidentify::configure_for Payment --file_path billing/payment
```

NOTE: the path provided must be the portion after `models`

This will generate a module at `app/concerns/deidentify/billing/`

```ruby
module Deidentify::Billing::PaymentPolicy
  ...
end
```

And will add the module into the model found at the path specified

```ruby
class Payment < ApplicationRecord
  include Deidentify::Billing::PaymentPolicy
  ...
end
```

## Contributing

Contributions are very welcome.

Please raise any problems you find as issues or create a pull request with a fix. Raise any new features as pull requests.

When contributing code please make sure that:
* The PR contains a detailed description of the feature or issue
* It is well tested
* All tests pass
* Rubocop reports no new warnings

## License

This gem is available as open source under the terms of the MIT License.
