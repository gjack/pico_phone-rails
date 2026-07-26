# frozen_string_literal: true

RSpec.describe "extract_phone_numbers_from with persist: true" do
  let(:model_class) do
    Class.new(ActiveRecord::Base) do
      self.table_name = "notes"
      def self.name = "Note"

      extract_phone_numbers_from :body, region: "US", persist: true
    end
  end

  it "persists a row for every match found in the attribute after save" do
    note = model_class.create!(body: "Call me at (510) 274-5656 or 415-555-0100")

    records = note.extracted_phone_number_records
    expect(records.map(&:e164)).to eq(["+15102745656", "+14155550100"])
    expect(records.map(&:source_attribute)).to eq(%w[body body])
    expect(records.map(&:raw_string)).to eq(["(510) 274-5656", "415-555-0100"])
  end

  it "keeps offsets that point back at the matched substring" do
    note = model_class.create!(body: "Call me at (510) 274-5656")

    record = note.extracted_phone_number_records.first
    expect(note.body[record.start_offset...record.end_offset]).to eq("(510) 274-5656")
  end

  it "re-syncs the persisted rows when the attribute changes" do
    note = model_class.create!(body: "call 510-274-5656")
    note.update!(body: "call 415-555-0100")

    expect(note.extracted_phone_number_records.map(&:e164)).to eq(["+14155550100"])
  end

  it "does not touch persisted rows when an unrelated save leaves the attribute unchanged" do
    note = model_class.create!(body: "call 510-274-5656")
    original_id = note.extracted_phone_number_records.first.id

    note.touch

    expect(note.extracted_phone_number_records.first.id).to eq(original_id)
  end

  it "removes persisted rows once the attribute no longer matches anything" do
    note = model_class.create!(body: "call 510-274-5656")
    note.update!(body: "no numbers anymore")

    expect(note.extracted_phone_number_records).to be_empty
  end

  it "destroys persisted rows when the record is destroyed" do
    note = model_class.create!(body: "call 510-274-5656")
    record_id = note.extracted_phone_number_records.first.id

    note.destroy!

    expect(PicoPhone::Rails::ExtractedPhoneNumber.find_by(id: record_id)).to be_nil
  end

  describe ".containing_phone_number" do
    it "finds a record regardless of how the number was formatted in the text" do
      note = model_class.create!(body: "Call me at (510) 274-5656")

      expect(model_class.containing_phone_number("510-274-5656")).to eq([note])
      expect(model_class.containing_phone_number("+15102745656")).to eq([note])
    end

    it "returns no results when nothing matches" do
      model_class.create!(body: "call 510-274-5656")

      expect(model_class.containing_phone_number("415-555-0100")).to be_empty
    end

    it "raises PersistenceNotEnabled for a model that never opted into persist: true" do
      not_persisted_class = Class.new(ActiveRecord::Base) do
        self.table_name = "notes"
        def self.name = "Note"

        extract_phone_numbers_from :body, region: "US"
      end

      expect { not_persisted_class.containing_phone_number("510-274-5656") }
        .to raise_error(PicoPhone::Rails::PersistenceNotEnabled, /persist: true/)
    end
  end

  describe "national_digits" do
    it "stores the digits of the displayed national format, not the E.164 national significant number" do
      note = model_class.create!(body: "call 510-274-5656")

      expect(note.extracted_phone_number_records.first.national_digits).to eq("5102745656")
    end

    it "keeps the trunk-prefix digit a viewer would actually type, for regions that have one" do
      fr_model_class = Class.new(ActiveRecord::Base) do
        self.table_name = "notes"
        def self.name = "Note"

        extract_phone_numbers_from :body, region: "FR", persist: true
      end

      note = fr_model_class.create!(body: "01 23 45 67 89")

      expect(note.extracted_phone_number_records.first.national_digits).to eq("0123456789")
    end
  end

  describe ".phone_number_starting_with" do
    it "matches a locally-formatted prefix the way a viewer would type it" do
      note = model_class.create!(body: "Call me at (510) 274-5656")

      expect(model_class.phone_number_starting_with("(510)")).to eq([note])
    end

    it "returns no results when the prefix doesn't match" do
      model_class.create!(body: "call 510-274-5656")

      expect(model_class.phone_number_starting_with("(415)")).to be_empty
    end

    it "raises PersistenceNotEnabled for a model that never opted into persist: true" do
      not_persisted_class = Class.new(ActiveRecord::Base) do
        self.table_name = "notes"
        def self.name = "Note"

        extract_phone_numbers_from :body, region: "US"
      end

      expect { not_persisted_class.phone_number_starting_with("(510)") }
        .to raise_error(PicoPhone::Rails::PersistenceNotEnabled, /persist: true/)
    end
  end

  describe "region" do
    it "persists the resolved region alongside the other derived columns" do
      note = model_class.create!(body: "call 510-274-5656")

      expect(note.extracted_phone_number_records.first.region).to eq("US")
    end

    context "with a per-record region (Symbol)" do
      let(:dynamic_model_class) do
        Class.new(ActiveRecord::Base) do
          self.table_name = "notes"
          def self.name = "Note"

          extract_phone_numbers_from :body, region: :region_for_phone_parsing, persist: true

          def region_for_phone_parsing
            region_code
          end
        end
      end

      it "resolves the region per record instead of a single fixed value" do
        us_note = dynamic_model_class.create!(body: "call 510-274-5656", region_code: "US")
        fr_note = dynamic_model_class.create!(body: "call 01 23 45 67 89", region_code: "FR")

        expect(us_note.extracted_phone_number_records.first.e164).to eq("+15102745656")
        expect(us_note.extracted_phone_number_records.first.region).to eq("US")
        expect(fr_note.extracted_phone_number_records.first.e164).to eq("+33123456789")
        expect(fr_note.extracted_phone_number_records.first.region).to eq("FR")
      end

      it "raises RegionRequired when searching without an explicit region override" do
        expect { dynamic_model_class.containing_phone_number("510-274-5656") }
          .to raise_error(PicoPhone::Rails::RegionRequired, /region:/)
      end

      it "finds records when the searching caller passes an explicit region" do
        note = dynamic_model_class.create!(body: "call 510-274-5656", region_code: "US")

        expect(dynamic_model_class.containing_phone_number("510-274-5656", region: "US")).to eq([note])
      end
    end

    context "with a per-record region (Proc)" do
      let(:proc_model_class) do
        Class.new(ActiveRecord::Base) do
          self.table_name = "notes"
          def self.name = "Note"

          extract_phone_numbers_from :body, region: lambda(&:region_code), persist: true
        end
      end

      it "resolves the region by calling the proc with the record" do
        note = proc_model_class.create!(body: "call 01 23 45 67 89", region_code: "FR")

        expect(note.extracted_phone_number_records.first.e164).to eq("+33123456789")
        expect(note.extracted_phone_number_records.first.region).to eq("FR")
      end
    end
  end

  describe "multiple tracked attributes" do
    let(:multi_attribute_class) do
      Class.new(ActiveRecord::Base) do
        self.table_name = "notes"
        def self.name = "Note"

        extract_phone_numbers_from :body, region: "US", persist: true
        extract_phone_numbers_from :subject, region: "US", persist: true
      end
    end

    it "scopes persisted rows by source_attribute independently" do
      note = multi_attribute_class.create!(body: "call 510-274-5656", subject: "re: 415-555-0100")

      by_attribute = note.extracted_phone_number_records.group_by(&:source_attribute)
      expect(by_attribute["body"].map(&:e164)).to eq(["+15102745656"])
      expect(by_attribute["subject"].map(&:e164)).to eq(["+14155550100"])
    end

    it "re-syncing one attribute leaves the other attribute's rows untouched" do
      note = multi_attribute_class.create!(body: "call 510-274-5656", subject: "re: 415-555-0100")
      subject_record_id = note.extracted_phone_number_records.find_by(source_attribute: "subject").id

      note.update!(body: "call 202-555-0173")

      expect(note.extracted_phone_number_records.find_by(source_attribute: "subject").id).to eq(subject_record_id)
      expect(note.extracted_phone_number_records.find_by(source_attribute: "body").e164).to eq("+12025550173")
    end
  end
end
