# frozen_string_literal: true

require_relative "support/dummy_app"

RSpec.describe PicoPhone::Rails::Engine do
  subject(:session) { ActionDispatch::Integration::Session.new(DummyApp) }

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
