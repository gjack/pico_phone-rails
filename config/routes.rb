# frozen_string_literal: true

PicoPhone::Rails::Engine.routes.draw do
  post "validate", to: "validations#validate"
end
