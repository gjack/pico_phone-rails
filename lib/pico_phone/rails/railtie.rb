# frozen_string_literal: true

require "rails/railtie"

module PicoPhone
  module Rails
    class Railtie < ::Rails::Railtie
      initializer "pico_phone_rails.type" do
        ActiveSupport.on_load(:active_record) do
          ActiveRecord::Type.register(:phone_number, PicoPhone::Rails::Type)
        end
      end

      initializer "pico_phone_rails.normalizer" do
        ActiveSupport.on_load(:active_record) do
          include PicoPhone::Rails::Normalizer
        end
      end

      initializer "pico_phone_rails.active_job_serializer" do
        ActiveSupport.on_load(:active_job) do
          require "pico_phone/rails/serializers/phone_number_serializer"
          ActiveJob::Serializers.add_serializers(PicoPhone::Rails::Serializers::PhoneNumberSerializer)
        end
      end

      initializer "pico_phone_rails.i18n" do |app|
        app.config.i18n.load_path += Dir[File.expand_path("locale/*.yml", __dir__)]
      end
    end
  end
end
