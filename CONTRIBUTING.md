# Contributing to pico_phone-rails

Bug reports and pull requests are welcome on GitHub at https://github.com/gjack/pico_phone-rails.

## Setup

```bash
git clone https://github.com/gjack/pico_phone-rails.git
cd pico_phone-rails
bundle install
bundle exec rake   # runs the specs and RuboCop
```

## Running the tests

```bash
bundle exec rspec    # specs only
bundle exec rubocop  # lint only
bundle exec rake     # both
```

## Testing across the Rails/Ruby support matrix

This gem supports Rails 7.0–8.1 and Ruby 3.1–4.0. The default `Gemfile` only
installs the latest of each for fast local iteration; before opening a PR,
check the full matrix with [Appraisal](https://github.com/thoughtbot/appraisal):

```bash
bundle exec appraisal install
bundle exec appraisal rake
```

CI runs this same matrix on every push and PR.

## Making changes

- New features should include specs and, if user-facing, a README example.
- Each feature lives in its own file under `lib/pico_phone/rails/` (or
  `lib/phone_validator.rb` for the top-level validator — see that file's
  comment for why it isn't namespaced) and is wired into
  `ActiveRecord`/`ActiveJob` from `lib/pico_phone/rails/railtie.rb` via
  `ActiveSupport.on_load`, so integrations stay soft dependencies that only
  load when the host app actually uses that Rails component.
- Specs don't boot a full `Rails::Application`, so anything the railtie would
  normally register needs the equivalent manual setup added to
  `spec/spec_helper.rb` — see the existing `ActiveRecord::Type.register` /
  `ActiveJob::Serializers.add_serializers` calls there for the pattern.

## Pull requests

- Keep PRs focused — one concern per PR makes review easier.
- The PR template will prompt you for a summary and test plan checklist.
- Branch protection requires all CI checks (the full Ruby × Rails matrix,
  lint, and CodeQL) to pass before merging.
