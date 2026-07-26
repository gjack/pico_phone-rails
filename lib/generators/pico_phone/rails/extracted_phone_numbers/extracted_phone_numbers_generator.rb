# frozen_string_literal: true

require "rails/generators"
require "rails/generators/migration"
require "rails/generators/active_record"

module PicoPhone
  module Rails
    # Invoked as `rails generate pico_phone:rails:extracted_phone_numbers`.
    # Creates the migration for the table `extract_phone_numbers_from ...,
    # persist: true` needs -- this is never run automatically, since a
    # gem shouldn't silently add tables to an app's schema.
    class ExtractedPhoneNumbersGenerator < ::Rails::Generators::Base
      include ::Rails::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      # @param dirname [String]
      # @return [String]
      def self.next_migration_number(dirname)
        ::ActiveRecord::Generators::Base.next_migration_number(dirname)
      end

      # @return [void]
      def create_migration_file
        migration_template(
          "create_pico_phone_rails_extracted_phone_numbers.rb.tt",
          "db/migrate/create_pico_phone_rails_extracted_phone_numbers.rb"
        )
      end
    end
  end
end
