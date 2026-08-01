# frozen_string_literal: true

require "active_record"
require "active_job"
# On Rails 7.0, `require "active_job"` only registers autoloads --
# ActiveJob::Arguments (which our serializer needs) isn't actually loaded
# until ActiveJob::Base is. A real app loads Base during Rails boot; specs
# have to trigger it explicitly.
require "active_job/base"
require "action_view"
require "pico_phone/rails"
require "pico_phone/rails/serializers/phone_number_serializer"
require "pico_phone/rails/extracted_phone_number"
require "pico_phone/rails/form_helper"

# Specs don't boot a full Rails::Application, so PicoPhone::Rails::Railtie's
# initializers never run. Wire up the same pieces they would register.
ActiveRecord::Type.register(:phone_number, PicoPhone::Rails::Type)
ActiveRecord::Base.include(PicoPhone::Rails::Normalizer)
ActiveRecord::Base.include(PicoPhone::Rails::Extraction)
ActiveRecord::Base.include(PicoPhone::Rails::PhoneSearchIndex)
ActiveJob::Serializers.add_serializers(PicoPhone::Rails::Serializers::PhoneNumberSerializer)
ActionView::Base.include(PicoPhone::Rails::FormHelper)
ActionView::Helpers::FormBuilder.include(PicoPhone::Rails::FormBuilderExtension)
I18n.load_path << File.expand_path("../lib/pico_phone/rails/locale/en.yml", __dir__)
I18n.backend.load_translations

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

ActiveRecord::Schema.verbose = false
ActiveRecord::Schema.define do
  create_table :contacts, force: true do |t|
    t.string :phone
  end

  create_table :notes, force: true do |t|
    t.text :body
    t.text :subject
    t.string :region_code
  end

  create_table :pico_phone_rails_extracted_phone_numbers, force: true do |t|
    t.references :extractable, polymorphic: true, null: false
    t.string :source_attribute, null: false
    t.string :region, null: false
    t.string :e164, null: false
    t.string :national_digits, null: false
    t.string :raw_string, null: false
    t.integer :start_offset, null: false
    t.integer :end_offset, null: false
    t.timestamps
  end
  # Explicit short names: the default generated name ("index_..._on_national_digits")
  # exceeds the 64-character limit Rails 7.0's sqlite3 adapter enforces, given
  # how long this table's name already is.
  add_index :pico_phone_rails_extracted_phone_numbers, :e164,
            name: "index_pico_phone_extracted_phone_numbers_on_e164"
  add_index :pico_phone_rails_extracted_phone_numbers, :national_digits,
            name: "index_pico_phone_extracted_phone_numbers_on_national_digits"

  create_table :phone_numbers, force: true do |t|
    t.string :number
    t.string :location
    t.string :region_code
    t.string :e164
    t.string :national_digits
    t.string :reverse_index
    t.string :region
  end
end

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"

  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # The sqlite connection (and its in-memory database) is shared across the
  # whole suite, so persisted-extraction specs that actually save records
  # would otherwise leak rows into later examples.
  config.around do |example|
    ActiveRecord::Base.transaction(requires_new: true) do
      example.run
      raise ActiveRecord::Rollback
    end
  end
end
