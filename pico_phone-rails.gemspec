# frozen_string_literal: true

require_relative "lib/pico_phone/rails/version"

Gem::Specification.new do |spec|
  spec.name = "pico_phone-rails"
  spec.version = PicoPhone::Rails::VERSION
  spec.authors = ["Gabi Jack"]
  spec.email = ["gabi@gabijack.com"]

  spec.summary = "Rails integration for pico_phone: attribute type, validator, normalizer, and ActiveJob serializer"
  spec.description = "pico_phone-rails wires the pico_phone gem into Rails: a :phone_number ActiveRecord " \
                     "attribute type, a PhoneValidator for ActiveModel validations, a normalize_phone " \
                     "class macro that rewrites phone attributes to E.164 before validation, and an " \
                     "ActiveJob serializer so a PhoneNumber survives being passed as a job argument."
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
    "lib/pico_phone/rails/railtie.rb",
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
