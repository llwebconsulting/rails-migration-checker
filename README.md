# Migrations

A Ruby gem to validate Rails migrations in CI, helping catch common migration issues early in the development process.

## Features

- Validates migration file structure and naming
- Checks for missing `down` methods
- Detects potential data loss issues (e.g., `drop_table` without `create_table`)
- Validates migration version sequence
- Checks for gaps in migration versions
- Safe tools to fix common migration issues
- Analyzes migration dependencies and detects circular dependencies
- Validates migration reversibility

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

### Rake Tasks

The gem provides several rake tasks to help fix common migration issues safely:

```bash
# Analyze migrations for potential issues
$ rake migrations:analyze

# Fix missing down methods by adding safe defaults
$ rake migrations:fix_missing_down

# Check for version gaps in migrations
$ rake migrations:fix_version_gaps

# Check for potential data loss in migrations
$ rake migrations:check_data_loss

# Generate a backup of all migrations
$ rake migrations:backup_plan

# Fix missing timestamps in tables
$ rake migrations:fix_missing_timestamps

# Fix missing foreign key constraints
$ rake migrations:fix_missing_foreign_keys

# Analyze migration dependencies
$ rake migrations:analyze_dependencies
```

#### Important Notes About Rake Tasks

1. **Safety First**: All tasks that modify migrations will create backups before making changes
2. **Review Required**: Always review the changes before committing them
3. **Production Warning**: Be extra careful when fixing migrations that have been applied to production
4. **Backup**: Always create a backup of your migrations before running any fix tasks
5. **Dependencies**: The `analyze_dependencies` task can help identify circular dependencies and ensure proper migration ordering

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