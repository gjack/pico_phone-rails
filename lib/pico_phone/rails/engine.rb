# frozen_string_literal: true

require "rails/engine"
require "pico_phone/rails/validations_controller"

module PicoPhone
  module Rails
    class Engine < ::Rails::Engine
      isolate_namespace PicoPhone::Rails

      initializer "pico_phone_rails.assets" do |app|
        app.config.assets.paths << Pathname.new(__dir__).join("javascript") if app.config.respond_to?(:assets)
      end

      # `before: "importmap"`: importmap-rails draws config.importmap.paths inside
      # its own "importmap" initializer, in one pass -- appending after that pass
      # is a no-op. Safe to declare unconditionally: if importmap-rails isn't
      # installed, there's no "importmap" initializer to order against.
      initializer "pico_phone_rails.importmap", before: "importmap" do |app|
        next unless app.config.respond_to?(:importmap)

        app.config.importmap.paths << Pathname.new(__dir__).join("javascript.rb")
        app.config.importmap.cache_sweepers << Pathname.new(__dir__).join("javascript")
      end
    end
  end
end
