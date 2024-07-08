[< Back to Navigation](../README.md)

# Specs and Linting

1. [Running specs and linting](#running-specs-and-linting)
2. [Running specs](#running-specs)
3. [Running linting with auto correct](#running-linting-with-auto-correct)

The NPQ app users RSpec for testing and [Rubocop](https://github.com/rubocop/rubocop) for linting ruby code.

The linting rules we use are inherited from [RuboCop GOV.UK](https://github.com/alphagov/rubocop-govuk) to ensure consistency across GOV.UK services. These are enforced at the PR stage by Github Actions.

## Running specs and linting

This will run rspec, rubocop, and scss-lint.
```
bundle exec rake
```

## Running specs

To run just rspec:
```
bundle exec rspec
```

## Running specs in parallel

### One time Setup
```
bundle exec rake parallel:setup
```

### Running specs thereafter
```
bundle exec rake parallel:spec
```

## Running linting with auto correct

To safely autocorrect offenses run:
```bash
bundle exec rubocop -a
```

To autocorrect all offenses, safe and unsafe, run:
```bash
bundle exec rubocop -A
```

To lint the stylesheets run:
```bash
bundle exec scss-lint app/assets/stylesheets
```
