# pico_phone-rails

Rails integration for [`pico_phone`](https://github.com/gjack/pico_phone): an
ActiveRecord attribute type, an ActiveModel validator, a before-validation
normalizer, free-text phone number extraction, a same-table phone search
index, and an ActiveJob serializer for phone numbers.

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

#### Persisting matches for cross-record search

```
rails generate pico_phone:rails:extracted_phone_numbers
rails db:migrate
```

```ruby
class Note < ApplicationRecord
  extract_phone_numbers_from :body, region: "US", persist: true
end

Note.containing_phone_number("(510) 274-5656")  # matches regardless of stored format
Note.phone_number_starting_with("(510)")        # matches a locally-formatted prefix
```

`persist: true` keeps a `pico_phone_rails_extracted_phone_numbers` row in sync
with the column on every save (only when it actually changes), so
`containing_phone_number` can find records by E.164 instead of grepping raw
text -- `"(510) 274-5656"`, `"5102745656"`, and `"+15102745656"` all match the
same row. `phone_number_starting_with` matches the digits of the number's
*displayed* national format, so a prefix like `"(510)"` matches the way a
viewer actually sees/types it. Calling either without having run the
generator and passed `persist: true` raises
`PicoPhone::Rails::PersistenceNotEnabled` with instructions, rather than a
bare "no such table" error.

`region:` also accepts a Symbol (called as an instance method on the record)
or a Proc (called with the record), for multi-tenant/multi-region apps where
the correct region varies per record instead of being fixed for the whole
model:

```ruby
extract_phone_numbers_from :body, region: ->(note) { note.campus.region }, persist: true
```

Since there's no single record to resolve a dynamic region against for a
class-level search, `containing_phone_number` requires an explicit `region:`
in that case (raising `PicoPhone::Rails::RegionRequired` otherwise):

```ruby
Note.containing_phone_number("01 23 45 67 89", region: current_organization.region)
```

### Phone search index

For a table that's already one-row-per-phone-number (rather than free text
that might mention one), `maintain_phone_search_index` keeps configurable
sibling search columns in sync via `before_save` -- no child table required.

Starting from scratch, with no phone-number table yet:

```
rails generate pico_phone:rails:phone_number PhoneNumber
rails db:migrate
```

This creates a `phone_numbers` table (raw `number` column plus all four
search-index columns, indexed) and an `app/models/phone_number.rb` with
`maintain_phone_search_index` already wired up -- just fill in `region:` for
your app. If you already have a table you want to add search columns to
instead, skip the generator and call `maintain_phone_search_index` directly:

```ruby
class PhoneNumber < ApplicationRecord
  maintain_phone_search_index :number,
    region: "US",
    columns: { e164: :e164, national_digits: :national_digits, reversed_digits: :reverse_index }
end
```

Each `columns:` entry is independently optional -- omit any you don't want
maintained. `reversed_digits` reverses the digit string so "ends with"/last-N
searches can use a leftmost-prefix index lookup. Unparseable input (which the
tracked column may deliberately allow) leaves every configured column `nil`
rather than failing the save.

To backfill rows that existed before you added the search index, use
`sync_phone_search_index!` -- the `before_save` callback only fires when the
tracked column *changes*, so re-saving an untouched row won't populate it:

```ruby
PhoneNumber.find_each(&:sync_phone_search_index!)
```

It writes immediately via `update_columns` (no callbacks, no validations),
same graceful `nil`-on-unparseable behavior as the regular sync.

Search against whichever columns you configured:

```ruby
PhoneNumber.phone_number_index_matching("(510) 274-5656")       # exact match via e164
PhoneNumber.phone_number_index_starting_with("(510)")            # prefix, the way a viewer types it
PhoneNumber.phone_number_index_ending_with("5656")                # last-N-digit suffix search
```

Each raises `PicoPhone::Rails::SearchColumnNotConfigured` if the column it
needs wasn't included in `columns:`. `phone_number_index_matching` also
accepts `region:` for interpreting an ambiguous query term, required
explicitly (raising `PicoPhone::Rails::RegionRequired` otherwise) when the
model's own `region:` is a Symbol/Proc rather than a fixed String -- same
reasoning as `containing_phone_number` above.

(These are named distinctly from Extraction's `containing_phone_number`/
`phone_number_starting_with` on purpose -- both concerns get included onto
every model, so identical names would collide and one would silently shadow
the other.)

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
