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

      # importmap-rails draws config.importmap.paths in its own "importmap"
      # initializer -- appending after that is a no-op, so this must run before.
      # A no-op itself if importmap-rails isn't installed.
      initializer "pico_phone_rails.importmap", before: "importmap" do |app|
        next unless app.config.respond_to?(:importmap)

        app.config.importmap.paths << Pathname.new(__dir__).join("javascript.rb")
        app.config.importmap.cache_sweepers << Pathname.new(__dir__).join("javascript")
      end
    end
  end
end
