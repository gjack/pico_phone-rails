# Changelog

## Unreleased

- Add `PicoPhone::Rails::Serializers::PhoneNumberSerializer`, an ActiveJob serializer so a `PhoneNumber` survives being passed directly as a job argument.

## 0.1.0 - 2026-07-25

- Initial release: `:phone_number` ActiveRecord attribute type, `PhoneValidator`, and `normalize_phone` before-validation macro.
