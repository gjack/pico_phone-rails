# frozen_string_literal: true

require_relative "lib/pico_phone/rails/version"

Gem::Specification.new do |spec|
  spec.name = "pico_phone-rails"
  spec.version = PicoPhone::Rails::VERSION
  spec.authors = ["Gabi Jack"]
  spec.email = ["gabi@gabijack.com"]

  spec.summary = "Rails integration for pico_phone: attribute type, validator, normalizer, " \
                 "free-text extraction, phone search index, form field helpers, live validation, " \
                 "and ActiveJob serializer"
  spec.description = "pico_phone-rails wires the pico_phone gem into Rails: a :phone_number ActiveRecord " \
                     "attribute type, a PhoneValidator for ActiveModel validations, a normalize_phone " \
                     "class macro that rewrites phone attributes to E.164 before validation, " \
                     "extract_phone_numbers_from for pulling phone numbers out of free text (with an " \
                     "optional persisted backend for cross-record search), maintain_phone_search_index " \
                     "for keeping search columns in sync on an existing phone-number table, " \
                     "pico_phone_field_tag/f.pico_phone_field form helpers that display national " \
                     "format for a valid number without discarding what the user typed, live: true " \
                     "on those same helpers for debounced Stimulus-driven validation and reformatting " \
                     "via a mountable engine, and an ActiveJob serializer so a PhoneNumber survives " \
                     "being passed as a job argument."
  spec.homepage = "https://github.com/gjack/pico_phone-rails"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/gjack/pico_phone-rails"
  spec.metadata["changelog_uri"] = "https://github.com/gjack/pico_phone-rails/releases"
  spec.metadata["bug_tracker_uri"] = "https://github.com/gjack/pico_phone-rails/issues"
  spec.metadata["documentation_uri"] = "https://rubydoc.info/gems/pico_phone-rails"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = [
    "lib/pico_phone/rails.rb",
    "lib/pico_phone/rails/version.rb",
    "lib/pico_phone/rails/region_resolution.rb",
    "lib/pico_phone/rails/type.rb",
    "lib/pico_phone/rails/normalizer.rb",
    "lib/pico_phone/rails/extraction.rb",
    "lib/pico_phone/rails/extracted_phone_number.rb",
    "lib/pico_phone/rails/phone_search_index.rb",
    "lib/pico_phone/rails/form_helper.rb",
    "lib/pico_phone/rails/railtie.rb",
    "lib/pico_phone/rails/engine.rb",
    "lib/pico_phone/rails/validations_controller.rb",
    "lib/pico_phone/rails/javascript.rb",
    "lib/pico_phone/rails/javascript/pico_phone/rails/phone_controller.js",
    "config/routes.rb",
    "lib/pico_phone/rails/serializers/phone_number_serializer.rb",
    "lib/pico_phone/rails/locale/en.yml",
    "lib/phone_validator.rb",
    "lib/generators/pico_phone/rails/extracted_phone_numbers/extracted_phone_numbers_generator.rb",
    "lib/generators/pico_phone/rails/extracted_phone_numbers/templates/" \
    "create_pico_phone_rails_extracted_phone_numbers.rb.tt",
    "lib/generators/pico_phone/rails/phone_number/phone_number_generator.rb",
    "lib/generators/pico_phone/rails/phone_number/templates/create_table.rb.tt",
    "lib/generators/pico_phone/rails/phone_number/templates/model.rb.tt",
    "LICENSE.txt",
    "README.md"
  ]
  spec.require_paths = ["lib"]

  spec.add_dependency "activemodel", ">= 7.0"
  spec.add_dependency "pico_phone", ">= 0.6"
  spec.add_dependency "railties", ">= 7.0"
end
