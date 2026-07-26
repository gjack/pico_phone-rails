# frozen_string_literal: true

require "active_support/concern"

module PicoPhone
  module Rails
    # Scans arbitrary text for phone numbers. Works on any string -- no
    # ActiveRecord model required.
    #
    # @param text [String, nil]
    # @param region [String] ISO 3166-1 alpha-2 default region for numbers found without a country code
    # @return [Array<PicoPhone::PhoneNumberMatch>]
    def self.extract_phone_numbers(text, region:)
      return [] if text.nil? || text.empty?

      PicoPhone.find_numbers(text, region)
    end

    # Replaces every phone number found in +text+ with +replacement+,
    # preserving everything else in the string untouched.
    #
    # @param text [String, nil]
    # @param region [String] ISO 3166-1 alpha-2 default region for numbers found without a country code
    # @param replacement [String]
    # @return [String]
    def self.redact_phone_numbers(text, region:, replacement: "[PHONE]")
      return text.to_s if text.nil? || text.empty?

      matches = extract_phone_numbers(text, region: region)
      return text.dup if matches.empty?

      splice_redactions(text, matches, replacement)
    end

    # @param text [String]
    # @param matches [Array<PicoPhone::PhoneNumberMatch>]
    # @param replacement [String]
    # @return [String]
    def self.splice_redactions(text, matches, replacement)
      segments = []
      cursor = 0
      matches.each do |match|
        segments << text.byteslice(cursor, match.start - cursor)
        segments << replacement
        cursor = match.end_index
      end
      segments << text.byteslice(cursor, text.bytesize - cursor)
      segments.join
    end
    private_class_method :splice_redactions

    # Included into ActiveRecord::Base by the railtie. Adds an
    # `extract_phone_numbers_from` class macro that wraps a free-text column
    # with helpers for pulling out and redacting the phone numbers it
    # mentions -- useful for notes, support tickets, and chat logs where a
    # phone number might appear anywhere in the text, in any format.
    #
    # @example
    #   class Note < ApplicationRecord
    #     extract_phone_numbers_from :body, region: "US"
    #   end
    #
    #   note.extracted_phone_numbers    # => [#<PicoPhone::PhoneNumberMatch ...>, ...]
    #   note.body_with_phones_redacted  # => "Call me at [PHONE] or [PHONE]"
    module Extraction
      extend ActiveSupport::Concern

      class_methods do
        # @!method extract_phone_numbers_from(attribute, region:)
        #   Defines +#extracted_phone_numbers+ and +#<attribute>_with_phones_redacted+
        #   on the including model, both backed by a live re-scan of +attribute+ --
        #   nothing is persisted or cached.
        #   @param attribute [Symbol] the text attribute to scan
        #   @param region [String] ISO 3166-1 alpha-2 default region for numbers found without a country code
        #   @return [void]
        def extract_phone_numbers_from(attribute, region:)
          define_method(:extracted_phone_numbers) do
            PicoPhone::Rails.extract_phone_numbers(public_send(attribute).to_s, region: region)
          end

          define_method("#{attribute}_with_phones_redacted") do
            PicoPhone::Rails.redact_phone_numbers(public_send(attribute).to_s, region: region)
          end
        end
      end
    end
  end
end
