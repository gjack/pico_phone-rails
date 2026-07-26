# frozen_string_literal: true

require "tmpdir"
require "generators/pico_phone/rails/phone_number/phone_number_generator"

RSpec.describe PicoPhone::Rails::PhoneNumberGenerator do
  it "generates a migration for a fresh table with all search-index columns" do
    Dir.mktmpdir do |destination_root|
      FileUtils.mkdir_p(File.join(destination_root, "db/migrate"))

      described_class.start(["PhoneNumber"], destination_root: destination_root)

      migration_path = Dir[File.join(destination_root, "db/migrate/*_create_phone_numbers.rb")].first
      expect(migration_path).not_to be_nil

      migration_source = File.read(migration_path)
      expect(migration_source).to include("class CreatePhoneNumbers")
      expect(migration_source).to include("create_table :phone_numbers")
      expect(migration_source).to include("t.string :number")
      expect(migration_source).to include("t.string :e164")
      expect(migration_source).to include("t.string :national_digits")
      expect(migration_source).to include("t.string :reversed_digits")
      expect(migration_source).to include("t.string :region")
      expect(migration_source).to include("add_index :phone_numbers, :e164")
      expect(migration_source).to include("add_index :phone_numbers, :national_digits")
      expect(migration_source).to include("add_index :phone_numbers, :reversed_digits")
    end
  end

  it "generates a starter model wired up with maintain_phone_search_index" do
    Dir.mktmpdir do |destination_root|
      FileUtils.mkdir_p(File.join(destination_root, "app/models"))

      described_class.start(["PhoneNumber"], destination_root: destination_root)

      model_source = File.read(File.join(destination_root, "app/models/phone_number.rb"))
      expect(model_source).to include("class PhoneNumber < ApplicationRecord")
      expect(model_source).to include("maintain_phone_search_index :number,")
      expect(model_source).to include("e164: :e164")
      expect(model_source).to include("national_digits: :national_digits")
      expect(model_source).to include("reversed_digits: :reversed_digits")
      expect(model_source).to include("region: :region")
    end
  end

  it "respects a custom model name for the table and class" do
    Dir.mktmpdir do |destination_root|
      FileUtils.mkdir_p(File.join(destination_root, "db/migrate"))
      FileUtils.mkdir_p(File.join(destination_root, "app/models"))

      described_class.start(["ContactNumber"], destination_root: destination_root)

      migration_path = Dir[File.join(destination_root, "db/migrate/*_create_contact_numbers.rb")].first
      expect(migration_path).not_to be_nil
      expect(File.read(migration_path)).to include("create_table :contact_numbers")

      model_source = File.read(File.join(destination_root, "app/models/contact_number.rb"))
      expect(model_source).to include("class ContactNumber < ApplicationRecord")
    end
  end
end
