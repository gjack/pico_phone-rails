# frozen_string_literal: true

module PicoPhone
  module Rails
    # Computes what a phone field should display: the number's national
    # format if it parses validly, the raw string otherwise -- so a user
    # re-editing an invalid or partial number sees exactly what they typed,
    # not a blank or garbled reformat. Shared by {FormHelper} and
    # {FormBuilderExtension}.
    #
    # @param value [String, PicoPhone::PhoneNumber, nil]
    # @param region [String, nil] ISO 3166-1 alpha-2 region for interpreting +value+ when it's a raw string
    # @return [String, nil]
    def self.phone_field_display_value(value, region)
      return nil if value.nil?
      return (value.valid? ? value.national : value.to_s) if value.is_a?(PicoPhone::PhoneNumber)

      string = value.to_s
      return string if string.empty?

      phone_number = PicoPhone.parse(string, region)
      phone_number.valid? ? phone_number.national : string
    end

    # Included into ActionView::Base by the railtie once ActionView loads.
    # Adds +pico_phone_field_tag+, a +text_field_tag+-like helper that
    # displays national format for a valid number while leaving the
    # underlying +<input>+ free to submit whatever string the user types.
    #
    # Named distinctly from Rails' own +phone_field_tag+/+f.phone_field+
    # (a built-in alias for +telephone_field+, plain +<input type="tel">+
    # with no formatting) rather than overriding it -- redefining a core
    # Rails helper would silently change behavior for every +phone_field+
    # call in an app, not just ones backed by a PicoPhone-managed attribute.
    #
    # @example
    #   pico_phone_field_tag :phone, @contact.phone, region: "US"
    module FormHelper
      # @param name [String, Symbol]
      # @param value [String, PicoPhone::PhoneNumber, nil]
      # @param region [String, nil] ISO 3166-1 alpha-2 region for interpreting +value+ when it's a raw string
      # @return [String] an HTML-safe +<input type="tel">+ tag
      def pico_phone_field_tag(name, value = nil, region: nil, **options)
        display_value = PicoPhone::Rails.phone_field_display_value(value, region)
        text_field_tag(name, display_value, options.merge(type: "tel"))
      end
    end

    # Included into ActionView::Helpers::FormBuilder by the railtie once
    # ActionView loads. Adds +f.pico_phone_field+, mirroring
    # {FormHelper#pico_phone_field_tag} but bound to the form's object.
    #
    # @example
    #   f.pico_phone_field :phone, region: "US"
    #   f.pico_phone_field :phone, region: ->(contact) { contact.organization.region }
    module FormBuilderExtension
      # @param method [Symbol] the attribute to render
      # @param region [String, Symbol, Proc, nil] ISO 3166-1 alpha-2 region for interpreting the attribute's
      #   raw value when it isn't already a {PicoPhone::PhoneNumber} -- a String is used as-is, a Symbol is
      #   called as an instance method on the form's object, a Proc is called with the object, same resolution
      #   rules as {Extraction.extract_phone_numbers_from} and {PhoneSearchIndex.maintain_phone_search_index}
      # @return [String] an HTML-safe +<input type="tel">+ tag
      def pico_phone_field(method, region: nil, **options)
        resolved_region = PicoPhone::Rails.resolve_region(region, object)
        display_value = PicoPhone::Rails.phone_field_display_value(object.public_send(method), resolved_region)
        text_field(method, options.merge(value: display_value, type: "tel"))
      end
    end
  end
end
