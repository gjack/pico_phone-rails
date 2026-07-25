# frozen_string_literal: true

require "pico_phone"
require "pico_phone/rails/version"
require "phone_validator"
require "pico_phone/rails/type"
require "pico_phone/rails/normalizer"
require "pico_phone/rails/railtie" if defined?(Rails::Railtie)

module PicoPhone
  module Rails
    class Error < StandardError; end
  end
end
