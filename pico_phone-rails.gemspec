# frozen_string_literal: true

require_relative "lib/pico_phone/rails/version"

Gem::Specification.new do |spec|
  spec.name = "pico_phone-rails"
  spec.version = PicoPhone::Rails::VERSION
  spec.authors = ["Gabi Jack"]
  spec.email = ["gabi@gabijack.com"]

  spec.summary = "Rails integration for pico_phone: attribute type, validator, and normalizer for phone numbers"
  spec.description = "pico_phone-rails wires the pico_phone gem into Rails: a :phone_number ActiveRecord " \
                     "attribute type, a PhoneValidator for ActiveModel validations, and a normalize_phone " \
                     "class macro that rewrites phone attributes to E.164 before validation."
  spec.homepage = "https://github.com/gjack/pico_phone-rails"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/gjack/pico_phone-rails"
  spec.metadata["changelog_uri"] = "https://github.com/gjack/pico_phone-rails/releases"
  spec.metadata["bug_tracker_uri"] = "https://github.com/gjack/pico_phone-rails/issues"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = [
    "lib/pico_phone/rails.rb",
    "lib/pico_phone/rails/version.rb",
    "lib/pico_phone/rails/type.rb",
    "lib/pico_phone/rails/normalizer.rb",
    "lib/pico_phone/rails/railtie.rb",
    "lib/pico_phone/rails/locale/en.yml",
    "lib/phone_validator.rb",
    "LICENSE.txt",
    "README.md"
  ]
  spec.require_paths = ["lib"]

  spec.add_dependency "activemodel", ">= 7.0"
  spec.add_dependency "pico_phone", ">= 0.6"
  spec.add_dependency "railties", ">= 7.0"
end
