# frozen_string_literal: true

module PicoPhone
  module Rails
    # A single phone number match persisted from a free-text column by
    # `extract_phone_numbers_from ..., persist: true`. Required only once
    # ActiveRecord::Base exists -- see the railtie -- since it inherits from
    # it directly.
    #
    # Requires the table created by the `pico_phone:rails:extracted_phone_numbers`
    # generator.
    class ExtractedPhoneNumber < ActiveRecord::Base
      self.table_name = "pico_phone_rails_extracted_phone_numbers"

      belongs_to :extractable, polymorphic: true
    end
  end
end
