# frozen_string_literal: true

RSpec.describe PicoPhone::Rails::Normalizer do
  let(:model_class) do
    Class.new(ActiveRecord::Base) do
      self.table_name = "contacts"
      normalize_phone :phone, region: "US"
    end
  end

  it "rewrites a nationally formatted number to E.164 before validation" do
    contact = model_class.new(phone: "(510) 274-5656")
    contact.valid?
    expect(contact.phone).to eq("+15102745656")
  end

  it "leaves unparseable input untouched so a validator can flag it" do
    contact = model_class.new(phone: "garbage")
    contact.valid?
    expect(contact.phone).to eq("garbage")
  end

  it "leaves blank values untouched" do
    contact = model_class.new(phone: "")
    contact.valid?
    expect(contact.phone).to eq("")
  end

  it "pairs with the validator: raw input is normalized before validation runs" do
    combined_class = Class.new(ActiveRecord::Base) do
      self.table_name = "contacts"
      normalize_phone :phone, region: "US"
      validates :phone, phone: { region: "US" }
    end

    contact = combined_class.new(phone: "(510) 274-5656")
    expect(contact).to be_valid
    expect(contact.phone).to eq("+15102745656")
  end
end
