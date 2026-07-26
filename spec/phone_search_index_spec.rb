# frozen_string_literal: true

RSpec.describe PicoPhone::Rails::PhoneSearchIndex do
  let(:model_class) do
    Class.new(ActiveRecord::Base) do
      self.table_name = "phone_numbers"
      def self.name = "PhoneNumber"

      maintain_phone_search_index :number,
                                  region: "US",
                                  columns: { e164: :e164, national_digits: :national_digits,
                                             reversed_digits: :reverse_index, region: :region }
    end
  end

  it "populates every configured column from a valid number" do
    phone_number = model_class.create!(number: "(510) 274-5656")

    expect(phone_number.e164).to eq("+15102745656")
    expect(phone_number.national_digits).to eq("5102745656")
    expect(phone_number.reverse_index).to eq("5102745656".reverse)
    expect(phone_number.region).to eq("US")
  end

  it "keeps the trunk-prefix digit a viewer would actually type, for regions that have one" do
    fr_model_class = Class.new(ActiveRecord::Base) do
      self.table_name = "phone_numbers"
      def self.name = "PhoneNumber"

      maintain_phone_search_index :number, region: "FR", columns: { national_digits: :national_digits }
    end

    phone_number = fr_model_class.create!(number: "01 23 45 67 89")

    expect(phone_number.national_digits).to eq("0123456789")
  end

  it "leaves every configured column nil for genuinely unparseable input, without failing the save" do
    phone_number = model_class.create!(number: "not a phone number at all")

    expect(phone_number).to be_persisted
    expect(phone_number.e164).to be_nil
    expect(phone_number.national_digits).to be_nil
    expect(phone_number.reverse_index).to be_nil
    expect(phone_number.region).to be_nil
  end

  it "only maintains the columns explicitly configured, leaving others untouched" do
    partial_model_class = Class.new(ActiveRecord::Base) do
      self.table_name = "phone_numbers"
      def self.name = "PhoneNumber"

      maintain_phone_search_index :number, region: "US", columns: { national_digits: :national_digits }
    end

    phone_number = partial_model_class.create!(number: "(510) 274-5656")

    expect(phone_number.national_digits).to eq("5102745656")
    expect(phone_number.e164).to be_nil
    expect(phone_number.reverse_index).to be_nil
  end

  it "only re-syncs when the tracked attribute actually changes" do
    phone_number = model_class.create!(number: "(510) 274-5656", location: "home")
    phone_number.update!(national_digits: "0000000000")

    phone_number.update!(location: "work")

    expect(phone_number.reload.national_digits).to eq("0000000000")
  end

  it "re-syncs when the tracked attribute changes" do
    phone_number = model_class.create!(number: "(510) 274-5656")
    phone_number.update!(number: "415-555-0100")

    expect(phone_number.e164).to eq("+14155550100")
    expect(phone_number.national_digits).to eq("4155550100")
  end

  describe "#sync_phone_search_index!" do
    it "backfills an existing row that predates the search index, bypassing the change guard" do
      phone_number = model_class.create!(number: "(510) 274-5656")
      model_class.where(id: phone_number.id).update_all(e164: nil, national_digits: nil, reverse_index: nil,
                                                        region: nil)

      phone_number.reload.sync_phone_search_index!

      expect(phone_number.reload.e164).to eq("+15102745656")
      expect(phone_number.national_digits).to eq("5102745656")
      expect(phone_number.reverse_index).to eq("5102745656".reverse)
      expect(phone_number.region).to eq("US")
    end

    it "persists immediately via update_columns, without needing a subsequent save" do
      phone_number = model_class.create!(number: "(510) 274-5656")
      model_class.where(id: phone_number.id).update_all(e164: nil)

      phone_number.reload.sync_phone_search_index!

      expect(model_class.find(phone_number.id).e164).to eq("+15102745656")
    end

    it "leaves the columns nil for unparseable input instead of raising" do
      phone_number = model_class.create!(number: "not a phone number at all")

      expect { phone_number.sync_phone_search_index! }.not_to raise_error
      expect(phone_number.reload.e164).to be_nil
    end
  end

  describe ".phone_number_index_matching" do
    it "finds a record regardless of how the number was formatted" do
      phone_number = model_class.create!(number: "(510) 274-5656")

      expect(model_class.phone_number_index_matching("510-274-5656")).to eq([phone_number])
      expect(model_class.phone_number_index_matching("+15102745656")).to eq([phone_number])
    end

    it "returns no results when nothing matches" do
      model_class.create!(number: "(510) 274-5656")

      expect(model_class.phone_number_index_matching("415-555-0100")).to be_empty
    end

    it "raises SearchColumnNotConfigured when columns: didn't configure :e164" do
      no_e164_class = Class.new(ActiveRecord::Base) do
        self.table_name = "phone_numbers"
        def self.name = "PhoneNumber"

        maintain_phone_search_index :number, region: "US", columns: { national_digits: :national_digits }
      end

      expect { no_e164_class.phone_number_index_matching("510-274-5656") }
        .to raise_error(PicoPhone::Rails::SearchColumnNotConfigured, /:e164/)
    end
  end

  describe ".phone_number_index_starting_with" do
    it "matches a locally-formatted prefix the way a viewer would type it" do
      phone_number = model_class.create!(number: "(510) 274-5656")

      expect(model_class.phone_number_index_starting_with("(510)")).to eq([phone_number])
    end

    it "returns no results when the prefix doesn't match" do
      model_class.create!(number: "(510) 274-5656")

      expect(model_class.phone_number_index_starting_with("(415)")).to be_empty
    end
  end

  describe ".phone_number_index_ending_with" do
    it "matches the last digits of the number regardless of format" do
      phone_number = model_class.create!(number: "(510) 274-5656")

      expect(model_class.phone_number_index_ending_with("5656")).to eq([phone_number])
    end

    it "returns no results when the suffix doesn't match" do
      model_class.create!(number: "(510) 274-5656")

      expect(model_class.phone_number_index_ending_with("0000")).to be_empty
    end
  end

  describe "region: as a Symbol or Proc, resolved per record" do
    it "resolves a Symbol as an instance method call" do
      dynamic_model_class = Class.new(ActiveRecord::Base) do
        self.table_name = "phone_numbers"
        def self.name = "PhoneNumber"

        maintain_phone_search_index :number, region: :region_for_search_index, columns: { e164: :e164 }

        def region_for_search_index
          region_code
        end
      end

      phone_number = dynamic_model_class.create!(number: "01 23 45 67 89", region_code: "FR")

      expect(phone_number.e164).to eq("+33123456789")
    end

    it "resolves a Proc by calling it with the record" do
      dynamic_model_class = Class.new(ActiveRecord::Base) do
        self.table_name = "phone_numbers"
        def self.name = "PhoneNumber"

        maintain_phone_search_index :number, region: lambda(&:region_code), columns: { e164: :e164 }
      end

      phone_number = dynamic_model_class.create!(number: "01 23 45 67 89", region_code: "FR")

      expect(phone_number.e164).to eq("+33123456789")
    end

    it "raises RegionRequired when searching without an explicit region override" do
      dynamic_model_class = Class.new(ActiveRecord::Base) do
        self.table_name = "phone_numbers"
        def self.name = "PhoneNumber"

        maintain_phone_search_index :number, region: :region_for_search_index, columns: { e164: :e164 }

        def region_for_search_index
          region_code
        end
      end

      expect { dynamic_model_class.phone_number_index_matching("510-274-5656") }
        .to raise_error(PicoPhone::Rails::RegionRequired, /region:/)
    end

    it "finds records when the searching caller passes an explicit region" do
      dynamic_model_class = Class.new(ActiveRecord::Base) do
        self.table_name = "phone_numbers"
        def self.name = "PhoneNumber"

        maintain_phone_search_index :number, region: :region_for_search_index, columns: { e164: :e164 }

        def region_for_search_index
          region_code
        end
      end

      phone_number = dynamic_model_class.create!(number: "510-274-5656", region_code: "US")

      expect(dynamic_model_class.phone_number_index_matching("510-274-5656", region: "US")).to eq([phone_number])
    end
  end
end
