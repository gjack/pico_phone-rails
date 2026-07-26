# frozen_string_literal: true

module PicoPhone
  module Rails
    # Resolves a `region:` option that may be a plain region code, or --
    # for apps where the correct region varies per record (multi-tenant,
    # multi-region) -- a Symbol naming an instance method, or a Proc called
    # with the record. Shared by {Extraction} and {PhoneSearchIndex}.
    #
    # @param region [String, Symbol, Proc]
    # @param record [Object]
    # @return [String, nil]
    def self.resolve_region(region, record)
      case region
      when Symbol then record.public_send(region)
      when Proc then region.call(record)
      else region
      end
    end
  end
end
