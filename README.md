# pico_phone-rails

Rails integration for [`pico_phone`](https://github.com/gjack/pico_phone): an
ActiveRecord attribute type, an ActiveModel validator, a before-validation
normalizer, free-text phone number extraction, and an ActiveJob serializer
for phone numbers.

## Installation

```ruby
gem "pico_phone-rails"
```

## Usage

### Validator

```ruby
class Contact < ApplicationRecord
  validates :phone, phone: { region: "US", allow_blank: true }
end
```

Options:

- `region:` — ISO 3166-1 alpha-2 default region used to interpret national-format input
- `allow_blank:` — skip validation when the value is `nil` or empty
- `possible:` — use a looser "possible" check instead of full validity

### Attribute type

```ruby
class Contact < ApplicationRecord
  attribute :phone, :phone_number, region: "US"
end

contact.phone        # => #<PicoPhone::PhoneNumber ...>
contact.phone.e164   # => "+15102745656"
```

Reads deserialize to a `PicoPhone::PhoneNumber`; writes serialize back to E.164
when valid. `nil` and unparseable input survive the round-trip without raising.

### Normalizer

```ruby
class Contact < ApplicationRecord
  normalize_phone :phone, region: "US"
end
```

A `before_validation` callback that rewrites the column to E.164 when it parses
as valid, so formatting noise ("(510) 274-5656") is stripped before the
validator runs. Pairs naturally with the validator above.

### Extraction

```ruby
class Note < ApplicationRecord
  extract_phone_numbers_from :body, region: "US"
end

note.extracted_phone_numbers    # => [#<PicoPhone::PhoneNumberMatch ...>, ...]
note.body_with_phones_redacted  # => "Call me at [PHONE] or [PHONE]"
```

Scans a free-text column (notes, support tickets, chat logs) for phone
numbers of any format. Both methods re-scan the column live -- nothing is
persisted. Works without a model too:

```ruby
PicoPhone::Rails.extract_phone_numbers(text, region: "US")
PicoPhone::Rails.redact_phone_numbers(text, region: "US", replacement: "[PHONE]")
```

### ActiveJob serializer

```ruby
MyJob.perform_later(phone: PicoPhone.parse("+15102745656", "US"))
```

A `PicoPhone::PhoneNumber` passed as a job argument survives the round trip
through your queue backend (Sidekiq, Solid Queue, GoodJob, etc.) without
manually converting to/from a string — `perform` receives back a real
`PhoneNumber`, not the E.164 string it was serialized as.

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

The Rails/Ruby support matrix is exercised via [Appraisal](https://github.com/thoughtbot/appraisal):

```bash
bundle exec appraisal install
bundle exec appraisal rake
```

## Contributing

Bug reports and pull requests are welcome on GitHub — see
[CONTRIBUTING.md](CONTRIBUTING.md) for setup and guidelines.

## License

MIT — see [LICENSE.txt](LICENSE.txt).
