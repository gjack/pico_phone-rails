# frozen_string_literal: true

# Defined at the top level (not under PicoPhone::Rails) so ActiveModel's
# validator lookup resolves `validates :phone, phone: { ... }` to this class —
# EachValidator constantizes "#{key.to_s.camelize}Validator" against the
# including model's namespace up through Object, same convention the
# email_validator gem uses.
#
#   validates :phone, phone: { region: "US", allow_blank: true }
class PhoneValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if options[:allow_blank] && value.blank?

    return if phone_valid?(value.to_s)

    record.errors.add(attribute, :invalid_phone, **options.slice(:message))
  end

  private

  def phone_valid?(string)
    region = options[:region]

    if options[:possible]
      region ? PicoPhone.possible_for_country?(string, region) : PicoPhone.possible?(string)
    else
      region ? PicoPhone.valid_for_country?(string, region) : PicoPhone.valid?(string)
    end
  end
end
