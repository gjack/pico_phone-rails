# Changelog

## 0.6.0 - 2026-08-08

- Live validation now reformats a number valid for a *different* country than the field's `region:` (one carrying its own `+` or IDD country signal, e.g. `"+44 20 7946 0958"` or `"011 44 20 7946 0958"` dialed out of a US-configured field) to international format on blur, instead of leaving it as raw, unrecognized digits. A bare national-style number with no country signal of its own is left untouched -- there's no reliable way to tell which of several countries it might belong to from the digits alone.
- Add `strict:` to `pico_phone_field_tag`/`f.pico_phone_field` (default `true`), controlling whether a cross-country match also clears the live error state, independent of the reformatting: `strict: true` matches a `PhoneValidator` that enforces `region:`, `strict: false` matches one that accepts any valid country.
- Bump `json` to 2.21.2, fixing a low-severity heap-use-after-free in `JSON::ResumableParser#partial_value` present in 2.20.0-2.21.1.

## 0.5.0 - 2026-08-02

- Add live phone-field validation: mount `PicoPhone::Rails::Engine` and pass `live: true` to `pico_phone_field_tag`/`f.pico_phone_field` for a Stimulus controller that debounces input, shows an inline error via a JSON endpoint, and reformats the field to national format on blur. Ships as a plain ES module, auto-pinned into `importmap-rails` when present -- no build step, no hard Turbo/Stimulus dependency. Uses the host app's normal CSRF protection; the controller reads the token from the page and sends it with every request.

## 0.4.0 - 2026-07-26

- Add `pico_phone_field_tag`/`f.pico_phone_field`, a form helper that renders an `<input type="tel">` showing the number in national format when it parses validly, or exactly what the user typed otherwise. `region:` accepts a String, Symbol (instance method on the form's object), or Proc (called with the object), same resolution as `extract_phone_numbers_from`/`maintain_phone_search_index`. Named distinctly from Rails' own `phone_field`/`f.phone_field` (a core alias for `telephone_field`) rather than overriding it.

## 0.3.0 - 2026-07-26

- Add `extract_phone_numbers_from`, a concern that scans a free-text column (notes, support tickets, chat logs) for phone numbers, exposing `#extracted_phone_numbers` (live `PhoneNumberMatch` array) and `#<attribute>_with_phones_redacted`. Also available standalone via `PicoPhone::Rails.extract_phone_numbers`/`.redact_phone_numbers`, no ActiveRecord model required.
- Add `persist: true` to `extract_phone_numbers_from` for cross-record search: persists matches to a `pico_phone_rails_extracted_phone_numbers` table (generated via `rails generate pico_phone:rails:extracted_phone_numbers`) and adds `.containing_phone_number`/`.phone_number_starting_with` class methods that match regardless of how a number was formatted in the source text. Raises `PicoPhone::Rails::PersistenceNotEnabled` if called without `persist: true`, or `PicoPhone::Rails::RegionRequired` if a class-level search omits `region:` and the model's own region is resolved per record.
- Add `maintain_phone_search_index`, a concern for a table that's already one-row-per-phone-number: keeps configurable sibling search columns (`e164`, `national_digits`, `reversed_digits`, `region`) in sync via `before_save`, with `#sync_phone_search_index!` for backfilling existing rows and `.phone_number_index_matching`/`.phone_number_index_starting_with`/`.phone_number_index_ending_with` for querying them (each raises `PicoPhone::Rails::SearchColumnNotConfigured` if the column it needs wasn't included in `columns:`). `rails generate pico_phone:rails:phone_number` scaffolds a fresh table + model for apps starting from scratch.
- `region:` on both concerns now accepts a Symbol or Proc in addition to a String, resolved per record -- for multi-tenant/multi-region apps where the correct region varies by organization/campus rather than being fixed for the whole model.

## 0.2.1 - 2026-07-25

- Documentation only: add `CONTRIBUTING.md`, `llms.txt`, a `documentation_uri` gemspec entry, and YARD `@param`/`@return`/`@example` comments across the public API. No behavior changes.

## 0.2.0 - 2026-07-25

- Add `PicoPhone::Rails::Serializers::PhoneNumberSerializer`, an ActiveJob serializer so a `PhoneNumber` survives being passed directly as a job argument.

## 0.1.0 - 2026-07-25

- Initial release: `:phone_number` ActiveRecord attribute type, `PhoneValidator`, and `normalize_phone` before-validation macro.
