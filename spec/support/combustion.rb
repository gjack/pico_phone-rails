# frozen_string_literal: true

require "combustion"

# spec_helper.rb's bare `require "pico_phone/rails"` runs before Rails::Railtie
# exists (see its comment on why), so lib/pico_phone/rails/engine.rb never
# gets loaded via the gem's own require chain -- and spec/internal/config/
# routes.rb references PicoPhone::Rails::Engine directly, so it must already
# be defined before Combustion boots the internal app.
require "pico_phone/rails/engine"

Combustion.initialize! :action_controller, :action_view
