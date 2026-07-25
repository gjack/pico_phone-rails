# frozen_string_literal: true

module PicoPhone
  module Rails
    module Serializers
      # Registered with ActiveJob::Serializers in the railtie, only once
      # ActiveJob itself has loaded. Lets a PhoneNumber survive as a job
      # argument without the caller manually converting to/from a string.
      #
      # #to_s alone is enough to round-trip losslessly: E.164 is
      # region-independent for valid numbers, and for invalid/unparseable
      # input #to_s already falls back to the original string, which
      # reparses to the same #to_s/#valid? regardless of region.
      #
      # @example
      #   MyJob.perform_later(phone: PicoPhone.parse("+15102745656", "US"))
      class PhoneNumberSerializer < ActiveJob::Serializers::ObjectSerializer
        # @param phone_number [PicoPhone::PhoneNumber]
        # @return [Hash] JSON-safe payload; ActiveJob merges in its own reserved serializer-identity key
        def serialize(phone_number)
          super("value" => phone_number.to_s)
        end

        # @param hash [Hash] payload previously produced by {#serialize}
        # @return [PicoPhone::PhoneNumber]
        def deserialize(hash)
          PicoPhone.parse(hash["value"])
        end

        # The class this serializer handles -- ActiveJob::Serializers uses it
        # both for dispatch (default #serialize?) and, since ActiveJob 8.1, to
        # build a lookup index, which is why it must be public: earlier
        # ActiveJob versions accepted a private #klass, but 8.1+ warns (and
        # 8.2+ will raise) if it isn't public.
        # @return [Class]
        def klass
          PicoPhone::PhoneNumber
        end
      end
    end
  end
end
