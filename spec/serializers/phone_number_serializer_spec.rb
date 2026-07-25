# frozen_string_literal: true

RSpec.describe PicoPhone::Rails::Serializers::PhoneNumberSerializer do
  let(:serializer) { described_class.instance }

  it "only claims PhoneNumber instances" do
    expect(serializer.serialize?(PicoPhone.parse("5102745656", "US"))).to be true
    expect(serializer.serialize?("5102745656")).to be false
  end

  it "round-trips a valid number" do
    phone_number = PicoPhone.parse("5102745656", "US")
    hash = serializer.serialize(phone_number)
    deserialized = serializer.deserialize(hash)

    expect(deserialized).to be_a(PicoPhone::PhoneNumber)
    expect(deserialized.e164).to eq("+15102745656")
  end

  it "round-trips unparseable input without raising" do
    phone_number = PicoPhone.parse("garbage", "US")
    hash = serializer.serialize(phone_number)
    deserialized = serializer.deserialize(hash)

    expect(deserialized.to_s).to eq("garbage")
    expect(deserialized.valid?).to be false
  end

  it "round-trips a nil-input PhoneNumber" do
    phone_number = PicoPhone.parse(nil)
    hash = serializer.serialize(phone_number)
    deserialized = serializer.deserialize(hash)

    expect(deserialized.to_s).to eq("")
  end

  it "is registered with ActiveJob::Serializers" do
    expect(ActiveJob::Serializers.serializers).to include(described_class)
  end

  it "survives the full ActiveJob argument serialization path used by perform_later" do
    phone_number = PicoPhone.parse("5102745656", "US")

    serialized = ActiveJob::Arguments.serialize([{ phone: phone_number }])
    deserialized = ActiveJob::Arguments.deserialize(serialized)

    rebuilt_phone_number = deserialized.first[:phone]
    expect(rebuilt_phone_number).to be_a(PicoPhone::PhoneNumber)
    expect(rebuilt_phone_number.e164).to eq("+15102745656")
  end
end
