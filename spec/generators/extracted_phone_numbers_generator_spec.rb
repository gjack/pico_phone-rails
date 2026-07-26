# frozen_string_literal: true

require "tmpdir"
require "generators/pico_phone/rails/extracted_phone_numbers/extracted_phone_numbers_generator"

RSpec.describe PicoPhone::Rails::ExtractedPhoneNumbersGenerator do
  it "generates a migration that creates the extracted_phone_numbers table" do
    Dir.mktmpdir do |destination_root|
      FileUtils.mkdir_p(File.join(destination_root, "db/migrate"))

      described_class.start([], destination_root: destination_root)

      migration_path = Dir[File.join(destination_root,
                                     "db/migrate/*_create_pico_phone_rails_extracted_phone_numbers.rb")].first
      expect(migration_path).not_to be_nil

      migration_source = File.read(migration_path)
      expect(migration_source).to include("class CreatePicoPhoneRailsExtractedPhoneNumbers")
      expect(migration_source).to include("create_table :pico_phone_rails_extracted_phone_numbers")
      expect(migration_source).to include("t.references :extractable, polymorphic: true, null: false")
      expect(migration_source).to include("add_index :pico_phone_rails_extracted_phone_numbers, :e164")
    end
  end
end
