# Changelog

## 0.2.1 - 2026-07-25

- Documentation only: add `CONTRIBUTING.md`, `llms.txt`, a `documentation_uri` gemspec entry, and YARD `@param`/`@return`/`@example` comments across the public API. No behavior changes.

## 0.2.0 - 2026-07-25

- Add `PicoPhone::Rails::Serializers::PhoneNumberSerializer`, an ActiveJob serializer so a `PhoneNumber` survives being passed directly as a job argument.

## 0.1.0 - 2026-07-25

- Initial release: `:phone_number` ActiveRecord attribute type, `PhoneValidator`, and `normalize_phone` before-validation macro.
