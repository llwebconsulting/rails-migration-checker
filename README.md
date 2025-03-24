# Migrations

A Ruby gem to validate Rails migrations in CI, helping catch common migration issues early in the development process.

## Features

- Validates migration file structure and naming
- Checks for missing `down` methods
- Detects potential data loss issues (e.g., `drop_table` without `create_table`)
- Validates migration version sequence
- Checks for gaps in migration versions
- (Coming soon) Validates migration dependencies and reversibility

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'migrations', group: :development, require: false
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install migrations
```

## Usage

### Command Line

```bash
# Validate migrations in the default db/migrate directory
$ migrations validate

# Validate migrations in a custom directory
$ migrations validate path/to/migrations

# Enable strict validation mode
$ migrations validate --strict
```

### In CI

Add this to your CI configuration (e.g., GitHub Actions):

```yaml
name: Validate Migrations

on:
  pull_request:
    paths:
      - 'db/migrate/**'

jobs:
  validate-migrations:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.0'
          bundler-cache: true
      - name: Validate Migrations
        run: bundle exec migrations validate
```

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `rake test` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub.

## License

The gem is available as open source under the terms of the MIT License. 