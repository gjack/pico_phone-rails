# frozen_string_literal: true

require "active_support/concern"

module PicoPhone
  module Rails
    # Raised by the {PhoneSearchIndex} class-level search methods when the
    # column they need wasn't configured in `columns:`.
    class SearchColumnNotConfigured < Error; end

    # Included into ActiveRecord::Base by the railtie. Adds a
    # `maintain_phone_search_index` class macro for a table that's already
    # one-row-per-phone-number (unlike Extraction, which is for a free-text
    # column that might mention a number anywhere in it). Keeps configurable
    # sibling columns in sync via `before_save` -- no child table, no
    # polymorphic association.
    #
    # @example
    #   class PhoneNumber < ApplicationRecord
    #     maintain_phone_search_index :number,
    #       region: "US",
    #       columns: { e164: :e164, national_digits: :national_digits, reversed_digits: :reverse_index }
    #   end
    #
    #   PhoneNumber.phone_number_index_matching("(510) 274-5656")
    #   PhoneNumber.phone_number_index_starting_with("(510)")
    #   PhoneNumber.phone_number_index_ending_with("5656")
    module PhoneSearchIndex
      extend ActiveSupport::Concern

      included do
        class_attribute :pico_phone_rails_phone_search_columns, instance_accessor: false, default: {}
        class_attribute :pico_phone_rails_phone_search_region, instance_accessor: false, default: nil
      end

      class_methods do
        # @!method maintain_phone_search_index(attribute, region:, columns: {})
        #   Registers a +before_save+ callback (only when +attribute+ actually
        #   changes) that parses +attribute+ and writes the configured derived
        #   columns. Each entry in +columns:+ is independently optional -- omit
        #   any key you don't want maintained, e.g. to keep an existing
        #   hand-rolled column untouched.
        #
        #   Unparseable input (which +attribute+ may deliberately allow) leaves
        #   every configured column +nil+ rather than failing the save, since
        #   +PhoneNumber#e164+/+#national+ raise on input that can't be
        #   interpreted as a phone number attempt at all.
        #   @param attribute [Symbol] the column holding the raw phone number
        #   @param region [String, Symbol, Proc] see {Extraction.extract_phone_numbers_from} for resolution rules
        #   @param columns [Hash{Symbol => Symbol}] maps :e164, :national_digits, :reversed_digits, and/or :region
        #     (search-index concepts) to the actual column names to write them to
        #   @return [void]
        def maintain_phone_search_index(attribute, region:, columns: {})
          self.pico_phone_rails_phone_search_columns = columns
          self.pico_phone_rails_phone_search_region = region

          before_save(if: -> { public_send(:"#{attribute}_changed?") }) do
            pico_phone_rails_stage_phone_search_index(attribute, region, columns)
          end

          # @!method sync_phone_search_index!
          #   Recomputes and immediately persists the configured columns via
          #   +update_columns+ (no callbacks, no validations), regardless of
          #   whether +attribute+ has changed -- unlike the +before_save+
          #   above, which only fires on an actual change. Meant for
          #   backfilling existing rows, since dirty-tracking has no way to
          #   know an unmodified row was never synced in the first place:
          #     PhoneNumber.find_each(&:sync_phone_search_index!)
          #   @return [void]
          define_method(:sync_phone_search_index!) do
            resolved_region = PicoPhone::Rails.resolve_region(region, self)
            phone_number = PicoPhone.parse(public_send(attribute).to_s, resolved_region)
            values = pico_phone_rails_phone_search_index_values(phone_number, resolved_region, columns)
            update_columns(values)
          end
        end
      end

      class_methods do
        # @param term [String] a phone number in any format
        # @param region [String, nil] region for interpreting +term+ -- required if the model's own
        #   region is resolved per record (a Symbol or Proc); pass the searching user's own region
        # @raise [PicoPhone::Rails::SearchColumnNotConfigured] if +columns:+ didn't configure +:e164+
        # @raise [PicoPhone::Rails::RegionRequired] if +region+ is omitted and the model's region is per-record
        # @return [ActiveRecord::Relation]
        def phone_number_index_matching(term, region: nil)
          column = pico_phone_rails_phone_search_column!(:e164)
          resolved_region = region || pico_phone_rails_static_phone_search_region!

          e164 = PicoPhone.parse(term.to_s, resolved_region).e164
          where(column => e164)
        end

        # Matches against the digits of the number's *displayed* national format -- see
        # {Extraction::ClassMethods#phone_number_starting_with} for the "why" (national vs
        # raw_national digits), and the same caveat applies here.
        # @param prefix [String] a phone number prefix in any format, e.g. "(510)"
        # @raise [PicoPhone::Rails::SearchColumnNotConfigured] if +columns:+ didn't configure +:national_digits+
        # @return [ActiveRecord::Relation]
        def phone_number_index_starting_with(prefix)
          column = pico_phone_rails_phone_search_column!(:national_digits)
          digits = prefix.to_s.gsub(/\D/, "")
          where("#{column} LIKE ?", "#{digits}%")
        end

        # Matches against the reversed digits of the number's displayed national format, so a
        # last-N-digit search can use a leftmost-prefix index lookup instead of a full scan.
        # @param suffix [String] a phone number suffix in any format, e.g. "5656"
        # @raise [PicoPhone::Rails::SearchColumnNotConfigured] if +columns:+ didn't configure +:reversed_digits+
        # @return [ActiveRecord::Relation]
        def phone_number_index_ending_with(suffix)
          column = pico_phone_rails_phone_search_column!(:reversed_digits)
          digits = suffix.to_s.gsub(/\D/, "")
          where("#{column} LIKE ?", "#{digits.reverse}%")
        end
      end

      class_methods do
        private

        # @param key [Symbol]
        # @raise [PicoPhone::Rails::SearchColumnNotConfigured]
        # @return [Symbol]
        def pico_phone_rails_phone_search_column!(key)
          column = pico_phone_rails_phone_search_columns[key]
          return column if column

          raise SearchColumnNotConfigured,
                "#{name} didn't configure a :#{key} column -- add it to `columns:` in maintain_phone_search_index"
        end

        # @raise [PicoPhone::Rails::RegionRequired] if the configured region isn't a plain String
        # @return [String, nil]
        def pico_phone_rails_static_phone_search_region!
          region = pico_phone_rails_phone_search_region
          return region if region.nil? || region.is_a?(String)

          raise RegionRequired,
                "#{name}'s region is resolved per record (#{region.inspect}), so it can't be inferred for a " \
                "class-level search -- pass region: explicitly, e.g. " \
                "#{name}.phone_number_index_matching(term, region: current_organization.region)"
        end
      end

      # @param attribute [Symbol]
      # @param region [String, Symbol, Proc]
      # @param columns [Hash{Symbol => Symbol}]
      # @return [void]
      def pico_phone_rails_stage_phone_search_index(attribute, region, columns)
        resolved_region = PicoPhone::Rails.resolve_region(region, self)
        phone_number = PicoPhone.parse(public_send(attribute).to_s, resolved_region)

        pico_phone_rails_phone_search_index_values(phone_number, resolved_region, columns).each do |column, value|
          public_send("#{column}=", value)
        end
      end
      private :pico_phone_rails_stage_phone_search_index

      # @param phone_number [PicoPhone::PhoneNumber]
      # @param resolved_region [String]
      # @param columns [Hash{Symbol => Symbol}]
      # @return [Hash{Symbol => String, nil}] actual column name => value to write
      def pico_phone_rails_phone_search_index_values(phone_number, resolved_region, columns)
        e164 = pico_phone_rails_safe_phone_call(phone_number, :e164)
        national_digits = pico_phone_rails_safe_phone_call(phone_number, :national)&.gsub(/\D/, "")

        values = {
          e164: e164,
          national_digits: national_digits,
          reversed_digits: national_digits&.reverse,
          region: (resolved_region if e164)
        }

        columns.each_with_object({}) { |(key, column), result| result[column] = values[key] }
      end
      private :pico_phone_rails_phone_search_index_values

      # @param phone_number [PicoPhone::PhoneNumber]
      # @param method_name [Symbol]
      # @return [String, nil] +nil+ if +method_name+ raises on unparseable input
      def pico_phone_rails_safe_phone_call(phone_number, method_name)
        phone_number.public_send(method_name)
      rescue TypeError
        nil
      end
      private :pico_phone_rails_safe_phone_call
    end
  end
end
