# frozen_string_literal: true

require "rails/generators"
require "rails/generators/migration"
require "rails/generators/active_record"

module PicoPhone
  module Rails
    # Invoked as `rails generate pico_phone:rails:phone_number PhoneNumber`.
    # For apps starting a phone-number table from scratch -- unlike
    # `maintain_phone_search_index` itself, which has no generator on
    # purpose, since it needs to map onto whatever columns an *existing*
    # table already has.
    #
    # Generates a migration for a table with a raw `number` column plus all
    # four search-index columns (e164, national_digits, reversed_digits,
    # region), and a starter model with `maintain_phone_search_index`
    # already wired up.
    class PhoneNumberGenerator < ::Rails::Generators::NamedBase
      include ::Rails::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      # @param dirname [String]
      # @return [String]
      def self.next_migration_number(dirname)
        ::ActiveRecord::Generators::Base.next_migration_number(dirname)
      end

      # @return [void]
      def create_migration_file
        migration_template "create_table.rb.tt", "db/migrate/create_#{table_name}.rb"
      end

      # @return [void]
      def create_model_file
        template "model.rb.tt", "app/models/#{file_path}.rb"
      end

      private

      # @return [String]
      def migration_class_name
        "Create#{table_name.camelize}"
      end
    end
  end
end
