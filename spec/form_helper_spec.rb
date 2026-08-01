# frozen_string_literal: true

RSpec.describe "PicoPhone::Rails.phone_field_display_value" do
  it "renders a valid raw string in national format" do
    expect(PicoPhone::Rails.phone_field_display_value("5102745656", "US")).to eq("(510) 274-5656")
  end

  it "renders an already-parsed PhoneNumber in national format" do
    phone_number = PicoPhone.parse("5102745656", "US")

    expect(PicoPhone::Rails.phone_field_display_value(phone_number, nil)).to eq("(510) 274-5656")
  end

  it "falls back to the raw string for input that doesn't parse validly" do
    expect(PicoPhone::Rails.phone_field_display_value("garbage", "US")).to eq("garbage")
  end

  it "falls back to the raw string for a partial/possible-but-invalid number" do
    expect(PicoPhone::Rails.phone_field_display_value("5102745", "US")).to eq("5102745")
  end

  it "falls back to #to_s for an already-parsed but invalid PhoneNumber" do
    phone_number = PicoPhone.parse("garbage", "US")

    expect(PicoPhone::Rails.phone_field_display_value(phone_number, nil)).to eq("garbage")
  end

  it "returns nil for nil" do
    expect(PicoPhone::Rails.phone_field_display_value(nil, "US")).to be_nil
  end

  it "returns an empty string as-is without attempting to parse it" do
    expect(PicoPhone::Rails.phone_field_display_value("", "US")).to eq("")
  end

  it "doesn't need a region when the value is already unambiguous (E.164)" do
    expect(PicoPhone::Rails.phone_field_display_value("+15102745656", nil)).to eq("(510) 274-5656")
  end
end

RSpec.describe PicoPhone::Rails::FormHelper do
  let(:view) { ActionView::Base.empty }

  describe "#pico_phone_field_tag" do
    it "renders an input[type=tel] with the value in national format" do
      html = view.pico_phone_field_tag(:phone, "5102745656", region: "US")

      expect(html).to include('type="tel"')
      expect(html).to include('value="(510) 274-5656"')
      expect(html).to include('name="phone"')
    end

    it "falls back to the raw value for unparseable input" do
      html = view.pico_phone_field_tag(:phone, "garbage", region: "US")

      expect(html).to include('value="garbage"')
    end

    it "passes through other options" do
      html = view.pico_phone_field_tag(:phone, "5102745656", region: "US", class: "form-control")

      expect(html).to include('class="form-control"')
    end
  end
end

RSpec.describe PicoPhone::Rails::FormBuilderExtension do
  let(:contact_class) do
    Class.new do
      include ActiveModel::Model

      attr_accessor :phone, :region_code
    end
  end
  let(:view) { ActionView::Base.empty }

  def builder_for(record)
    ActionView::Helpers::FormBuilder.new(:contact, record, view, {})
  end

  describe "#pico_phone_field" do
    it "renders the object's attribute in national format" do
      contact = contact_class.new(phone: "5102745656")

      html = builder_for(contact).pico_phone_field(:phone, region: "US")

      expect(html).to include('type="tel"')
      expect(html).to include('value="(510) 274-5656"')
      expect(html).to include('name="contact[phone]"')
      expect(html).to include('id="contact_phone"')
    end

    it "falls back to the raw value for unparseable input" do
      contact = contact_class.new(phone: "garbage")

      html = builder_for(contact).pico_phone_field(:phone, region: "US")

      expect(html).to include('value="garbage"')
    end

    it "resolves region: as a Symbol called on the object" do
      contact = contact_class.new(phone: "01 23 45 67 89", region_code: "FR")
      def contact.region_for_phone_field = region_code

      html = builder_for(contact).pico_phone_field(:phone, region: :region_for_phone_field)

      expect(html).to include('value="01 23 45 67 89"')
    end

    it "resolves region: as a Proc called with the object" do
      contact = contact_class.new(phone: "01 23 45 67 89", region_code: "FR")

      html = builder_for(contact).pico_phone_field(:phone, region: lambda(&:region_code))

      expect(html).to include('value="01 23 45 67 89"')
    end

    it "doesn't need region: when the attribute is already a PhoneNumber" do
      contact = contact_class.new
      contact.define_singleton_method(:phone) { PicoPhone.parse("5102745656", "US") }

      html = builder_for(contact).pico_phone_field(:phone)

      expect(html).to include('value="(510) 274-5656"')
    end
  end
end
