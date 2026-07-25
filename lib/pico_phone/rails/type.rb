# frozen_string_literal: true

require "active_model"

module PicoPhone
  module Rails
    # Registered as `:phone_number` in the railtie. Casts a stored string to a
    # PicoPhone::PhoneNumber on read and serializes back to E.164 on write.
    #
    # @example
    #   attribute :phone, :phone_number, region: "US"
    #
    #   contact.phone       # => #<PicoPhone::PhoneNumber ...>
    #   contact.phone.e164  # => "+15102745656"
    class Type < ActiveModel::Type::Value
      # @param region [String, nil] ISO 3166-1 alpha-2 default region used to interpret national-format input
      def initialize(region: nil)
        @region = region
        super()
      end

      # @return [Symbol] always +:string+ -- the underlying column stores a plain string
      def type
        :string
      end

      # @param value [String, PicoPhone::PhoneNumber, nil]
      # @return [PicoPhone::PhoneNumber, nil] +nil+ for +nil+ input; never raises on unparseable input
      def cast(value)
        return value if value.is_a?(PicoPhone::PhoneNumber)
        return nil if value.nil?

        PicoPhone.parse(value.to_s, @region)
      end

      # @param value [String, PicoPhone::PhoneNumber, nil]
      # @return [String, nil] E.164 for a valid number, the original string for an invalid one, +nil+ for +nil+ input
      def serialize(value)
        return nil if value.nil?

        phone_number = value.is_a?(PicoPhone::PhoneNumber) ? value : PicoPhone.parse(value.to_s, @region)
        phone_number.valid? ? phone_number.e164 : phone_number.to_s
      end

      # @param value [String, nil] raw value read from the database
      # @return [PicoPhone::PhoneNumber, nil]
      def deserialize(value)
        cast(value)
      end
    end
  end
end
