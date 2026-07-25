# frozen_string_literal: true

module PicoPhone
  module Rails
    module Serializers
      # Registered with ActiveJob::Serializers in the railtie, only once
      # ActiveJob itself has loaded. Lets a PhoneNumber survive as a job
      # argument without the caller manually converting to/from a string:
      #
      #   MyJob.perform_later(phone: PicoPhone.parse("+15102745656", "US"))
      #
      # #to_s alone is enough to round-trip losslessly: E.164 is
      # region-independent for valid numbers, and for invalid/unparseable
      # input #to_s already falls back to the original string, which
      # reparses to the same #to_s/#valid? regardless of region.
      class PhoneNumberSerializer < ActiveJob::Serializers::ObjectSerializer
        def serialize(phone_number)
          super("value" => phone_number.to_s)
        end

        def deserialize(hash)
          PicoPhone.parse(hash["value"])
        end

        # Public since ActiveJob 8.1: Serializers.serializer_for builds a
        # lookup index keyed by this, and warns (raising from 8.2 on) if
        # it's private.
        def klass
          PicoPhone::PhoneNumber
        end
      end
    end
  end
end
