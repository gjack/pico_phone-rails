# frozen_string_literal: true

RSpec.describe PicoPhone::Rails::Extraction do
  let(:model_class) do
    Class.new(ActiveRecord::Base) do
      self.table_name = "notes"
      extract_phone_numbers_from :body, region: "US"
    end
  end

  describe "#extracted_phone_numbers" do
    it "returns a match for every phone number mentioned in the text" do
      note = model_class.new(body: "Call me at (510) 274-5656 or 415-555-0100 tomorrow")

      numbers = note.extracted_phone_numbers.map { |match| match.number.e164 }

      expect(numbers).to eq(["+15102745656", "+14155550100"])
    end

    it "returns an empty array when the text has no phone numbers" do
      note = model_class.new(body: "no numbers here")

      expect(note.extracted_phone_numbers).to eq([])
    end

    it "returns an empty array for a blank attribute" do
      note = model_class.new(body: nil)

      expect(note.extracted_phone_numbers).to eq([])
    end

    it "exposes the raw match text and position alongside the parsed number" do
      note = model_class.new(body: "Call me at (510) 274-5656")

      match = note.extracted_phone_numbers.first

      expect(match.raw_string).to eq("(510) 274-5656")
      expect(note.body[match.start...match.end_index]).to eq("(510) 274-5656")
    end
  end

  describe "#<attribute>_with_phones_redacted" do
    it "replaces each matched number with the redaction placeholder" do
      note = model_class.new(body: "Call me at (510) 274-5656 or 415-555-0100 tomorrow")

      expect(note.body_with_phones_redacted).to eq("Call me at [PHONE] or [PHONE] tomorrow")
    end

    it "leaves text with no phone numbers untouched" do
      note = model_class.new(body: "no numbers here")

      expect(note.body_with_phones_redacted).to eq("no numbers here")
    end

    it "returns an empty string for a blank attribute" do
      note = model_class.new(body: nil)

      expect(note.body_with_phones_redacted).to eq("")
    end
  end

  describe "region: as a Symbol or Proc, resolved per record" do
    it "resolves a Symbol as an instance method call" do
      dynamic_model_class = Class.new(ActiveRecord::Base) do
        self.table_name = "notes"
        extract_phone_numbers_from :body, region: :region_for_phone_parsing

        def region_for_phone_parsing
          region_code
        end
      end

      note = dynamic_model_class.new(body: "01 23 45 67 89", region_code: "FR")

      expect(note.extracted_phone_numbers.first.number.e164).to eq("+33123456789")
    end

    it "resolves a Proc by calling it with the record" do
      dynamic_model_class = Class.new(ActiveRecord::Base) do
        self.table_name = "notes"
        extract_phone_numbers_from :body, region: lambda(&:region_code)
      end

      note = dynamic_model_class.new(body: "01 23 45 67 89", region_code: "FR")

      expect(note.extracted_phone_numbers.first.number.e164).to eq("+33123456789")
    end
  end
end

RSpec.describe "PicoPhone::Rails.extract_phone_numbers" do
  it "works on a plain string with no ActiveRecord model involved" do
    numbers = PicoPhone::Rails.extract_phone_numbers("reach me at +1 510-274-5656", region: "US")
                              .map { |match| match.number.e164 }

    expect(numbers).to eq(["+15102745656"])
  end

  it "returns an empty array for nil or empty text" do
    expect(PicoPhone::Rails.extract_phone_numbers(nil, region: "US")).to eq([])
    expect(PicoPhone::Rails.extract_phone_numbers("", region: "US")).to eq([])
  end
end

RSpec.describe "PicoPhone::Rails.redact_phone_numbers" do
  it "accepts a custom replacement" do
    redacted = PicoPhone::Rails.redact_phone_numbers(
      "call 510-274-5656", region: "US", replacement: "***"
    )

    expect(redacted).to eq("call ***")
  end

  it "preserves multi-byte text surrounding a match" do
    redacted = PicoPhone::Rails.redact_phone_numbers("téléphone: 510-274-5656 – merci", region: "US")

    expect(redacted).to eq("téléphone: [PHONE] – merci")
  end
end
