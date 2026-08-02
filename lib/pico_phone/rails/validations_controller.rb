# frozen_string_literal: true

require "action_controller"

module PicoPhone
  module Rails
    # `region:` always arrives as an already-resolved String -- no record lookup.
    # No state changes here (no session, no persistence), so nothing for CSRF
    # to protect -- explicit skip_forgery_protection rather than relying on
    # ActionController::API's structural absence of the module, so a scanner
    # (or a future reader) sees a deliberate choice, not an omission.
    class ValidationsController < ActionController::Base
      skip_forgery_protection

      def validate
        phone = params[:phone].to_s
        return render json: { valid: false, blank: true } if phone.strip.empty?

        phone_number = PicoPhone.parse(phone, params[:region].presence)

        if phone_number.valid?
          render json: {
            valid: true,
            blank: false,
            e164: safe_phone_call(phone_number, :e164),
            national: safe_phone_call(phone_number, :national)
          }
        else
          render json: { valid: false, blank: false, message: I18n.t("errors.messages.invalid_phone") }
        end
      end

      private

      # @return [String, nil] nil if unparseable, matching PhoneSearchIndex's guard
      def safe_phone_call(phone_number, method_name)
        phone_number.public_send(method_name)
      rescue TypeError
        nil
      end
    end
  end
end
