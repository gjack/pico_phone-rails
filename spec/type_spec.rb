# frozen_string_literal: true

RSpec.describe PicoPhone::Rails::Type do
  let(:model_class) do
    Class.new(ActiveRecord::Base) do
      self.table_name = "contacts"
      attribute :phone, :phone_number, region: "US"
    end
  end

  it "casts a stored string to a PhoneNumber on read" do
    contact = model_class.new(phone: "5102745656")
    expect(contact.phone).to be_a(PicoPhone::PhoneNumber)
    expect(contact.phone.e164).to eq("+15102745656")
  end

  it "serializes a valid number to E.164 for storage" do
    contact = model_class.create!(phone: "(510) 274-5656")
    raw = model_class.connection.select_value("SELECT phone FROM contacts WHERE id = #{contact.id}")
    expect(raw).to eq("+15102745656")
  end

  it "round-trips unparseable input via #to_s without raising" do
    contact = model_class.create!(phone: "garbage")
    expect(model_class.find(contact.id).phone.to_s).to eq("garbage")
  end

  it "round-trips nil without raising" do
    contact = model_class.create!(phone: nil)
    expect(contact.phone).to be_nil
    expect(model_class.find(contact.id).phone).to be_nil
  end

  it "accepts an already-cast PhoneNumber on write" do
    phone_number = PicoPhone.parse("5102745656", "US")
    contact = model_class.create!(phone: phone_number)
    expect(contact.phone.e164).to eq("+15102745656")
  end
end
