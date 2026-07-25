# frozen_string_literal: true

require "active_model"

module PicoPhone
  module Rails
    # Registered as `:phone_number` in the railtie. Casts a stored string to a
    # PicoPhone::PhoneNumber on read and serializes back to E.164 on write.
    #
    #   attribute :phone, :phone_number, region: "US"
    class Type < ActiveModel::Type::Value
      def initialize(region: nil)
        @region = region
        super()
      end

      def type
        :string
      end

      def cast(value)
        return value if value.is_a?(PicoPhone::PhoneNumber)
        return nil if value.nil?

        PicoPhone.parse(value.to_s, @region)
      end

      def serialize(value)
        return nil if value.nil?

        phone_number = value.is_a?(PicoPhone::PhoneNumber) ? value : PicoPhone.parse(value.to_s, @region)
        phone_number.valid? ? phone_number.e164 : phone_number.to_s
      end

      def deserialize(value)
        cast(value)
      end
    end
  end
end
