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

    # Raised by `containing_phone_number` when the including model never
    # opted into `persist: true` (or its migration hasn't been run), instead
    # of an obscure ActiveRecord::StatementInvalid: no such table.
    class PersistenceNotEnabled < Error; end

    # Raised by `containing_phone_number` when the model's `region:` is
    # resolved per record (a Symbol or Proc, for multi-tenant/multi-region
    # apps) and the caller didn't pass an explicit `region:` -- there's no
    # single record to resolve it against at the class level.
    class RegionRequired < Error; end

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
    #
    # @example Persisting matches for cross-record search
    #   class Note < ApplicationRecord
    #     extract_phone_numbers_from :body, region: "US", persist: true
    #   end
    #
    #   Note.containing_phone_number("(510) 274-5656") # matches regardless of stored format
    module Extraction
      extend ActiveSupport::Concern

      included do
        class_attribute :pico_phone_rails_persisted, instance_accessor: false, default: false
        class_attribute :pico_phone_rails_extraction_region, instance_accessor: false, default: nil
      end

      class_methods do
        # @!method extract_phone_numbers_from(attribute, region:, persist: false)
        #   Defines +#extracted_phone_numbers+ and +#<attribute>_with_phones_redacted+
        #   on the including model, both backed by a live re-scan of +attribute+ --
        #   nothing is persisted or cached by default.
        #
        #   When +persist: true+, also declares a +has_many :extracted_phone_number_records+
        #   association and an +after_save+ callback that keeps it in sync with
        #   +attribute+, so {.containing_phone_number} can find records by phone
        #   number regardless of how it was formatted in the source text. Requires
        #   the table created by the `pico_phone:rails:extracted_phone_numbers`
        #   generator.
        #   @param attribute [Symbol] the text attribute to scan
        #   @param region [String, Symbol, Proc] ISO 3166-1 alpha-2 default region for numbers found without a
        #     country code. A String is used as-is; a Symbol is called as an instance method on the record; a
        #     Proc is called with the record. Either lets the region vary per record, e.g.
        #     `region: ->(note) { note.campus.region }`, for multi-tenant/multi-region apps, rather than being
        #     fixed once for the whole model.
        #   @param persist [Boolean] persist matches for cross-record search via {.containing_phone_number}
        #   @return [void]
        def extract_phone_numbers_from(attribute, region:, persist: false)
          define_method(:extracted_phone_numbers) do
            resolved_region = PicoPhone::Rails.resolve_region(region, self)
            PicoPhone::Rails.extract_phone_numbers(public_send(attribute).to_s, region: resolved_region)
          end

          define_method("#{attribute}_with_phones_redacted") do
            resolved_region = PicoPhone::Rails.resolve_region(region, self)
            PicoPhone::Rails.redact_phone_numbers(public_send(attribute).to_s, region: resolved_region)
          end

          return unless persist

          persist_extracted_phone_numbers_from(attribute, region)
        end
      end

      class_methods do
        # @param term [String] a phone number in any format
        # @param region [String, nil] ISO 3166-1 alpha-2 region for interpreting +term+ -- required if the
        #   model's own region is resolved per record (a Symbol or Proc), since there's no record to resolve
        #   it against here; pass the searching user's own region, e.g. `region: current_organization.region`
        # @raise [PicoPhone::Rails::PersistenceNotEnabled] if no attribute was registered with +persist: true+
        # @raise [PicoPhone::Rails::RegionRequired] if +region+ is omitted and the model's region is per-record
        # @return [ActiveRecord::Relation]
        def containing_phone_number(term, region: nil)
          ensure_pico_phone_rails_persisted!
          resolved_region = region || pico_phone_rails_static_extraction_region!

          e164 = PicoPhone.parse(term.to_s, resolved_region).e164
          joins(:extracted_phone_number_records)
            .where(PicoPhone::Rails::ExtractedPhoneNumber.table_name => { e164: e164 })
            .distinct
        end

        # Matches against the digits of the number's *displayed* national
        # format (e.g. "5102745656", or "0123456789" for a French number
        # whose national format shows a leading trunk "0") -- what a viewer
        # would actually type while looking at the number, rather than the
        # E.164 "national significant number" (which drops that trunk digit).
        #
        # @param prefix [String] a phone number prefix in any format, e.g. "(510)"
        # @raise [PicoPhone::Rails::PersistenceNotEnabled] if no attribute was registered with +persist: true+
        # @return [ActiveRecord::Relation]
        def phone_number_starting_with(prefix)
          ensure_pico_phone_rails_persisted!

          digits = prefix.to_s.gsub(/\D/, "")
          joins(:extracted_phone_number_records)
            .where("#{PicoPhone::Rails::ExtractedPhoneNumber.table_name}.national_digits LIKE ?", "#{digits}%")
            .distinct
        end
      end

      class_methods do
        private

        # @raise [PicoPhone::Rails::PersistenceNotEnabled]
        # @return [void]
        def ensure_pico_phone_rails_persisted!
          return if pico_phone_rails_persisted

          raise PersistenceNotEnabled,
                "#{name} has no attribute registered with `extract_phone_numbers_from ..., persist: true` -- " \
                "add persist: true and run the pico_phone:rails:extracted_phone_numbers generator"
        end

        # @raise [PicoPhone::Rails::RegionRequired] if the configured region isn't a plain String
        # @return [String, nil]
        def pico_phone_rails_static_extraction_region!
          region = pico_phone_rails_extraction_region
          return region if region.nil? || region.is_a?(String)

          raise RegionRequired,
                "#{name}'s region is resolved per record (#{region.inspect}), so it can't be inferred for a " \
                "class-level search -- pass region: explicitly, e.g. " \
                "#{name}.containing_phone_number(term, region: current_organization.region)"
        end
      end

      class_methods do
        # @param attribute [Symbol]
        # @param region [String]
        # @return [void]
        private def persist_extracted_phone_numbers_from(attribute, region)
          self.pico_phone_rails_persisted = true
          self.pico_phone_rails_extraction_region = region

          has_many :extracted_phone_number_records,
                   class_name: "PicoPhone::Rails::ExtractedPhoneNumber",
                   as: :extractable,
                   dependent: :delete_all

          after_save(if: -> { public_send(:"saved_change_to_#{attribute}?") }) do
            pico_phone_rails_sync_extracted_phone_numbers(attribute, region)
          end
        end
      end

      # @param attribute [Symbol]
      # @param region [String, Symbol, Proc]
      # @return [void]
      def pico_phone_rails_sync_extracted_phone_numbers(attribute, region)
        resolved_region = PicoPhone::Rails.resolve_region(region, self)
        matches = PicoPhone::Rails.extract_phone_numbers(public_send(attribute).to_s, region: resolved_region)

        extracted_phone_number_records.where(source_attribute: attribute.to_s).delete_all
        return if matches.empty?

        rows = matches.map do |match|
          pico_phone_rails_extracted_phone_number_attributes(match, attribute, resolved_region)
        end
        extracted_phone_number_records.insert_all(rows)
      end
      private :pico_phone_rails_sync_extracted_phone_numbers

      # @param match [PicoPhone::PhoneNumberMatch]
      # @param attribute [Symbol]
      # @param region [String] the region actually resolved for this record, persisted for auditability
      # @return [Hash]
      def pico_phone_rails_extracted_phone_number_attributes(match, attribute, region)
        {
          source_attribute: attribute.to_s,
          region: region,
          e164: match.number.e164,
          national_digits: match.number.national.gsub(/\D/, ""),
          raw_string: match.raw_string,
          start_offset: match.start,
          end_offset: match.end_index
        }
      end
      private :pico_phone_rails_extracted_phone_number_attributes
    end
  end
end
