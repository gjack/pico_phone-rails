# frozen_string_literal: true

RSpec.describe PhoneValidator do
  # Anonymous ActiveRecord classes need a name for I18n error-message lookups
  # (ActiveModel::Naming raises on `model_name` otherwise), so stub_const gives
  # each one a real constant for the duration of the example.
  let(:model_class) do
    stub_const("Contact", Class.new(ActiveRecord::Base) do
      self.table_name = "contacts"
      validates :phone, phone: { region: "US", allow_blank: true }
    end)
  end

  it "is valid for a valid US number" do
    expect(model_class.new(phone: "5102745656")).to be_valid
  end

  it "is invalid for garbage input" do
    contact = model_class.new(phone: "garbage")
    expect(contact).not_to be_valid
    expect(contact.errors[:phone]).to include("is not a valid phone number")
  end

  it "allows blank when allow_blank is true" do
    expect(model_class.new(phone: "")).to be_valid
  end

  context "without allow_blank" do
    let(:model_class) do
      stub_const("Contact", Class.new(ActiveRecord::Base) do
        self.table_name = "contacts"
        validates :phone, phone: { region: "US" }
      end)
    end

    it "is invalid for blank" do
      expect(model_class.new(phone: "")).not_to be_valid
    end
  end

  context "without a region" do
    let(:model_class) do
      stub_const("Contact", Class.new(ActiveRecord::Base) do
        self.table_name = "contacts"
        validates :phone, phone: {}
      end)
    end

    it "validates E.164 input directly" do
      expect(model_class.new(phone: "+15102745656")).to be_valid
    end

    it "rejects national-format input with no region hint to interpret it" do
      expect(model_class.new(phone: "5102745656")).not_to be_valid
    end
  end

  context "with possible: true" do
    let(:model_class) do
      stub_const("Contact", Class.new(ActiveRecord::Base) do
        self.table_name = "contacts"
        validates :phone, phone: { region: "US", possible: true }
      end)
    end

    it "accepts a number that is possible but not strictly valid" do
      expect(model_class.new(phone: "5100000000")).to be_valid
    end
  end

  it "rejects a number that is possible but not strictly valid when possible is not set" do
    expect(model_class.new(phone: "5100000000")).not_to be_valid
  end

  context "with a custom message" do
    let(:model_class) do
      stub_const("Contact", Class.new(ActiveRecord::Base) do
        self.table_name = "contacts"
        validates :phone, phone: { region: "US", message: "looks wrong" }
      end)
    end

    it "uses the custom message" do
      contact = model_class.new(phone: "garbage")
      contact.valid?
      expect(contact.errors[:phone]).to include("looks wrong")
    end
  end
end
