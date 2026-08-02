# frozen_string_literal: true

require "rails"
require "pico_phone/rails/engine"

class DummyApp < Rails::Application
  config.eager_load = false
  config.secret_key_base = "test"
  config.logger = Logger.new(File::NULL)
  config.hosts.clear
end
DummyApp.initialize!

# A route drawn before `initialize!` gets wiped by the same reload-from-files
# cycle that requires the engine's own config/routes.rb (see that file) --
# DummyApp has no on-disk routes.rb of its own, so this has to run after boot,
# once, with nothing left to trigger another reload in a spec run.
DummyApp.routes.draw { mount PicoPhone::Rails::Engine, at: "/pico_phone" }
