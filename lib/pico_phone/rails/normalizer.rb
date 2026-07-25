# frozen_string_literal: true

require "active_support/concern"

module PicoPhone
  module Rails
    # Included into ActiveRecord::Base by the railtie. Adds a `normalize_phone`
    # class macro that rewrites the given attributes to E.164 before validation
    # runs, so validators and persisted data see a consistent format.
    #
    # @example
    #   class Contact < ApplicationRecord
    #     normalize_phone :phone, region: "US"
    #   end
    module Normalizer
      extend ActiveSupport::Concern

      class_methods do
        # @!method normalize_phone(*attributes, region: nil)
        #   Registers a +before_validation+ callback that rewrites each attribute
        #   to E.164 when it parses as valid, leaving unparseable input untouched
        #   so a validator can flag it.
        #   @param attributes [Array<Symbol>] attribute names to normalize
        #   @param region [String, nil] ISO 3166-1 alpha-2 default region used to interpret national-format input
        #   @return [void]
        def normalize_phone(*attributes, region: nil)
          before_validation do
            attributes.each do |attribute|
              value = public_send(attribute)
              next if value.blank?

              phone_number = PicoPhone.parse(value.to_s, region)
              public_send("#{attribute}=", phone_number.e164) if phone_number.valid?
            end
          end
        end
      end
    end
  end
end
