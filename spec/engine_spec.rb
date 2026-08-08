# frozen_string_literal: true

require_relative "support/combustion"

RSpec.describe PicoPhone::Rails::Engine do
  subject(:session) { ActionDispatch::Integration::Session.new(Combustion::Application) }

  # Mirrors what phone_controller.js does: reads the CSRF token off the page
  # (rendering any page establishes one) and sends it as X-CSRF-Token.
  def post_validate(params)
    session.get("/live_field")
    token = session.response.body[/name="csrf-token" content="([^"]+)"/, 1]

    session.post("/pico_phone/validate", params: params.to_json,
                                         headers: { "Content-Type" => "application/json", "X-CSRF-Token" => token })
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

  it "formats a number valid for a different country as international, but keeps it invalid by default (strict)" do
    response = post_validate(phone: "+44 20 7946 0958", region: "US")

    expect(response).to eq(
      "valid" => false,
      "blank" => false,
      "e164" => "+442079460958",
      "international" => "+44 20 7946 0958",
      "message" => "is not a valid phone number"
    )
  end

  it "marks a number valid for a different country as valid when strict: false" do
    response = post_validate(phone: "+44 20 7946 0958", region: "US", strict: false)

    expect(response).to eq(
      "valid" => true,
      "blank" => false,
      "e164" => "+442079460958",
      "international" => "+44 20 7946 0958"
    )
  end

  it "stays invalid and unformatted for ambiguous national-style digits with no country code" do
    response = post_validate(phone: "020 7946 0958", region: "US")

    expect(response).to eq(
      "valid" => false,
      "blank" => false,
      "message" => "is not a valid phone number"
    )
  end

  it "recognizes a foreign number dialed via the region's own IDD exit code, with no +" do
    response = post_validate(phone: "011 44 20 7946 0958", region: "US")

    expect(response).to eq(
      "valid" => false,
      "blank" => false,
      "e164" => "+442079460958",
      "international" => "+44 20 7946 0958",
      "message" => "is not a valid phone number"
    )
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
    expect(html).to include('data-phone-strict-value="true"')
    expect(html).to include('data-phone-url-value="/pico_phone/validate"')
  end

  it "reflects strict: false when passed to pico_phone_field_tag" do
    session.get("/live_field_strict_false", params: { value: "5102745656", region: "US" })
    html = session.response.body

    expect(html).to include('data-phone-strict-value="false"')
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
