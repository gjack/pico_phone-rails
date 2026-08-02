# frozen_string_literal: true

require_relative "support/combustion"

RSpec.describe PicoPhone::Rails::Engine do
  subject(:session) { ActionDispatch::Integration::Session.new(Combustion::Application) }

  def post_validate(params)
    session.post("/pico_phone/validate", params: params)
    JSON.parse(session.response.body)
  end

  it "returns e164/national for a valid number" do
    response = post_validate(phone: "5102745656", region: "US")

    expect(response).to eq(
      "valid" => true,
      "blank" => false,
      "e164" => "+15102745656",
      "national" => "(510) 274-5656"
    )
  end

  it "returns a translated message for an invalid, non-blank number" do
    response = post_validate(phone: "123", region: "US")

    expect(response).to eq(
      "valid" => false,
      "blank" => false,
      "message" => "is not a valid phone number"
    )
  end

  it "flags blank input without an error message" do
    response = post_validate(phone: "", region: "US")

    expect(response).to eq("valid" => false, "blank" => true)
  end

  it "does not raise on genuinely unparseable input" do
    response = post_validate(phone: "not a phone number at all", region: "US")

    expect(response["valid"]).to be false
  end
end

RSpec.describe "live: true" do
  subject(:session) { ActionDispatch::Integration::Session.new(Combustion::Application) }

  it "wires pico_phone_field_tag up to the mounted engine" do
    session.get("/live_field", params: { value: "5102745656", region: "US" })
    html = session.response.body

    expect(html).to include('data-controller="phone"')
    expect(html).to include('data-action="input-&gt;phone#validate blur-&gt;phone#reformat"')
    expect(html).to include('data-phone-region-value="US"')
    expect(html).to include('data-phone-url-value="/pico_phone/validate"')
  end

  it "lets a caller-supplied data: win on key conflict" do
    session.get("/live_field_data_override", params: { value: "5102745656", region: "US" })
    html = session.response.body

    expect(html).to include('data-controller="custom-controller"')
    expect(html).to include('data-phone-region-value="US"')
  end

  it "wires f.pico_phone_field up to the mounted engine" do
    session.get("/live_field_form_builder", params: { value: "5102745656", region: "US" })
    html = session.response.body

    expect(html).to include('data-controller="phone"')
    expect(html).to include('data-phone-region-value="US"')
    expect(html).to include('data-phone-url-value="/pico_phone/validate"')
  end
end
