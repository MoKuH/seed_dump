Seed Dump
========

Seed Dump is a Rails 4 and 5 plugin that adds a rake task named `db:seed:dump`.

It allows you to create seed data files from the existing data in your database.

You can also use Seed Dump from the Rails console. See below for usage examples.

Note: if you want to use Seed Dump with Rails 3 or earlier, use [version 0.5.3](http://rubygems.org/gems/seed_dump/versions/0.5.3).

Installation
------------

Add it to your Gemfile with:
```ruby
gem 'seed_dump'
```
Or install it by hand:
```sh
$ gem install seed_dump
```
Examples
--------

### Rake task

Dump all data directly to `db/seeds.rb`:
```sh
  $ rake db:seed:dump
```
Result:
```ruby
Product.create!([
  { category_id: 1, description: "Long Sleeve Shirt", name: "Long Sleeve Shirt" },
  { category_id: 3, description: "Plain White Tee Shirt", name: "Plain T-Shirt" }
])
User.create!([
  { password: "123456", username: "test_1" },
  { password: "234567", username: "test_2" }
])
```

Dump only data from the users table and dump a maximum of 1 record:
```sh
$ rake db:seed:dump MODELS=User LIMIT=1
```

Result:
```ruby
User.create!([
  { password: "123456", username: "test_1" }
])
```

Append to `db/seeds.rb` instead of overwriting it:
```sh
rake db:seed:dump APPEND=true
```

Use another output file instead of `db/seeds.rb`:
```sh
rake db:seed:dump FILE=db/seeds/users.rb
```

Exclude `name` and `age` from the dump:
```sh
rake db:seed:dump EXCLUDE=name,age
```

There are more options that can be set— see below for all of them.

### Console

Output a dump of all User records:
```ruby
irb(main):001:0> puts SeedDump.dump(User)
User.create!([
  { password: "123456", username: "test_1" },
  { password: "234567", username: "test_2" }
])
```

Write the dump to a file:
```ruby
irb(main):002:0> SeedDump.dump(User, file: 'db/seeds.rb')
```

Append the dump to a file:
```ruby
irb(main):003:0> SeedDump.dump(User, file: 'db/seeds.rb', append: true)
```

Exclude `name` and `age` from the dump:
```ruby
irb(main):004:0> SeedDump.dump(User, exclude: [:name, :age])
```

Dump a model and associated has_* tables, in a way that they are re-associated upon loading:
```ruby
2.4.1 :001 > SeedDump.dump(FooMerchant, file: '/tmp/seeds2.rb', include_has_associations: true, follow_belongs_to: true)
(foo_merchant_685, foo_merchant_553) =  FooMerchant.create!([ { name:'merchant1'}, {name:'merchant2'} ])
(foo_merchant_address_702, foo_merchant_address_843) = FooMerchantAddress.create!([ { foo_merchant: foo_merchant_685, address1:'somewhere'},{ foo_merchant: foo_merchant_685, address1:'somewhere'} ])
```
                                                    
Options are specified as a Hash for the second argument.

In the console, any relation of ActiveRecord rows can be dumped (not individual objects though)
```ruby
irb(main):001:0> puts SeedDump.dump(User.where(is_admin: false))
User.create!([
  { password: "123456", username: "test_1", is_admin: false },
  { password: "234567", username: "test_2", is_admin: false }
])
```

Options
-------

Options are common to both the Rake task and the console, except where noted.

`append`: If set to `true`, append the data to the file instead of overwriting it. Default: `false`.

`batch_size`: Controls the number of records that are written to file at a given time. Default: 1000. If you're running out of memory when dumping, try decreasing this. If things are dumping too slow, trying increasing this.

`exclude`: Attributes to be excluded from the dump. Pass a comma-separated list to the Rake task (i.e. `name,age`) and an array on the console (i.e. `[:name, :age]`). Default: `[:id, :created_at, :updated_at]`.

`file`: Write to the specified output file. The Rake task default is `db/seeds.rb`. The console returns the dump as a string by default.

`import`: If `true`, output will be in the format needed by the [activerecord-import](https://github.com/zdennis/activerecord-import) gem, rather than the default format. Default: `false`.

`limit`: Dump no more than this amount of data. Default: no limit. Rake task only. In the console just pass in an ActiveRecord::Relation with the appropriate limit (e.g. `SeedDump.dump(User.limit(5))`).

`conditions`: Dump only specific records. In the console just pass in an ActiveRecord::Relation with the appropriate conditions (e.g. `SeedDump.dump(User.where(state: :active))`).

`model[s]`: Restrict the dump to the specified comma-separated list of models. Default: all models. If you are using a Rails engine you can dump a specific model by passing "EngineName::ModelName". Rake task only. Example: `rake db:seed:dump MODELS="User, Position, Function"`

`models_exclude`: Exclude the specified comma-separated list of models from the dump. Default: no models excluded. Rake task only. Example: `rake db:seed:dump MODELS_EXCLUDE="User"`

`references`: Generate references to created records to be used for has_many or has_one relationships in related models. Format of the variable name is model's class `underscore`'d with the current record id. Example: FooMerchant with id of 1000 will be assigned to `foo_merchant_1000` 

`include_has_associations`: Given a model, also dump it's has_* associations. Useful to combine with `references` option. Example: `SeedDump.dump(FooMerchant, file: '/tmp/seeds.rb', include_has_associations: true, references: true)` will dump the FooMerchant table, generating references that can be used for other-table associations, then will look for `has_many` and `has_one` associations, and dump those too. 