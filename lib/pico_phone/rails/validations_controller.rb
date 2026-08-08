# frozen_string_literal: true

require "action_controller"

module PicoPhone
  module Rails
    # `region:` always arrives as an already-resolved String -- no record lookup.
    class ValidationsController < ActionController::Base
      def validate
        phone = params[:phone].to_s
        return render json: { valid: false, blank: true } if phone.strip.empty?

        render json: response_for(phone, params[:region].presence)
      end

      private

      def response_for(phone, region)
        regional = PicoPhone.parse(phone, region)
        return regional_payload(regional) if matches_region?(regional, region)

        # `regional`'s #valid?/#country are scoped to `region` even when the input carries its
        # own country code (a leading "+" or a recognized IDD exit code, e.g. US's "011") --
        # #valid_countries isn't, since it works off the actually-extracted country code, and
        # #e164/#international are unaffected by the scoping either. No second parse needed.
        # A bare national-style number with no country code of its own (e.g. "020 7946 0958"
        # typed into a region: "US" field) stays invalid here -- #valid_countries comes back
        # empty because there's no signal pointing at any specific country to check against.
        return invalid_payload if regional.valid_countries.empty?

        cross_country_payload(regional)
      end

      def matches_region?(phone_number, region)
        region ? phone_number.valid_for_country?(region) : phone_number.valid?
      end

      def regional_payload(phone_number)
        {
          valid: true,
          blank: false,
          e164: safe_phone_call(phone_number, :e164),
          national: safe_phone_call(phone_number, :national)
        }
      end

      def cross_country_payload(phone_number)
        strict = params.fetch(:strict, true)
        payload = {
          valid: !strict,
          blank: false,
          e164: safe_phone_call(phone_number, :e164),
          international: safe_phone_call(phone_number, :international)
        }
        payload[:message] = invalid_message if strict
        payload
      end

      def invalid_payload
        { valid: false, blank: false, message: invalid_message }
      end

      def invalid_message
        I18n.t("errors.messages.invalid_phone")
      end

      # @return [String, nil] nil if unparseable, matching PhoneSearchIndex's guard
      def safe_phone_call(phone_number, method_name)
        phone_number.public_send(method_name)
      rescue TypeError
        nil
      end
    end
  end
end
