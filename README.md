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

### Secret Configuration

For the hashing deidenitification methods you can configure this gem to take a secret which will be used to salt the hashed values.
Do this by creating this file `config/initializers/deidentify.rb`

```ruby
Deidentify.configure do |config|
  config.salt = # Your secret value
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

### Lambda

You can pass a custom lambda as the deidentification method.

```ruby
deidentify :email, method: -> (email) { "deidentified@#{email.split("@").last}" }
```

### Keep

You can opt to leave a value untouched.

```ruby
deidentify :age, method: :keep
```

NOTE: You get the same behaviour by simply not specifing a deidentification method for a field.

`Keep` is designed so that it is possible to mark a field as not containing sensitive data. That makes it obvious which fields have been purposely not changed and which have been missed during development.

## Generator

This gem comes with a generator that will generate a deidentification module for a model. By calling

```
$ rails generate deidentify:configure_for Person
```

you will generate a module in `app/concerns/deidentify/` which will contain all columns of that model.

```ruby
module Deidentify::Person
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
  include Deidentify::Person
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
module Deidentify::Billing::Payment
  ...
end
```

And will add the module in the correct class

```ruby
class Billing::Payment < ApplicationRecord
  include Deidentify::Billing::Payment
  ...
end
```

### Specifing the file path

You can specify a file path if your path doesn't match your namespace.
For example if you have a model `Payment` which is found in `app/models/billing/payment.rb`

```
$ rails generate deidentify::configure_for Payment --file_path billing
```

NOTE: the path provided must be the portion after `models`

This will generate a module at `app/concerns/deidentify/billing/`

```ruby
module Deidentify::Billing::Payment
  ...
end
```

And will add the module into the model found at the path specified

```ruby
class Payment < ApplicationRecord
  include Deidentify::Billing::Payment
  ...
end
```
