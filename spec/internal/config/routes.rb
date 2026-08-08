# frozen_string_literal: true

Rails.application.routes.draw do
  mount PicoPhone::Rails::Engine, at: "/pico_phone"
  get "live_field", to: "live_field#show"
  get "live_field_data_override", to: "live_field#show_with_data_override"
  get "live_field_form_builder", to: "live_field#show_form_builder"
  get "live_field_strict_false", to: "live_field#show_strict_false"
end
