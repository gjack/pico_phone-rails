# frozen_string_literal: true

class LiveFieldController < ActionController::Base
  def show
    render inline: "<%= pico_phone_field_tag(:phone, params[:value], region: params[:region], live: true) %>"
  end

  def show_with_data_override
    render inline: <<~ERB
      <%= pico_phone_field_tag(:phone, params[:value], region: params[:region], live: true,
            data: { controller: "custom-controller" }) %>
    ERB
  end

  def show_form_builder
    contact = Struct.new(:phone).new(params[:value])
    render inline: <<~ERB, locals: { contact: contact }
      <%= form_with(model: contact, url: "/", scope: :contact) do |f| %>
        <%= f.pico_phone_field :phone, region: params[:region], live: true %>
      <% end %>
    ERB
  end
end
