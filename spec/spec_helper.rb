# frozen_string_literal: true

require "active_record"
require "active_job"
# On Rails 7.0, `require "active_job"` only registers autoloads --
# ActiveJob::Arguments (which our serializer needs) isn't actually loaded
# until ActiveJob::Base is. A real app loads Base during Rails boot; specs
# have to trigger it explicitly.
require "active_job/base"
require "pico_phone/rails"
require "pico_phone/rails/serializers/phone_number_serializer"

# Specs don't boot a full Rails::Application, so PicoPhone::Rails::Railtie's
# initializers never run. Wire up the same pieces they would register.
ActiveRecord::Type.register(:phone_number, PicoPhone::Rails::Type)
ActiveRecord::Base.include(PicoPhone::Rails::Normalizer)
ActiveJob::Serializers.add_serializers(PicoPhone::Rails::Serializers::PhoneNumberSerializer)
I18n.load_path << File.expand_path("../lib/pico_phone/rails/locale/en.yml", __dir__)
I18n.backend.load_translations

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

ActiveRecord::Schema.verbose = false
ActiveRecord::Schema.define do
  create_table :contacts, force: true do |t|
    t.string :phone
  end
end

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"

  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
