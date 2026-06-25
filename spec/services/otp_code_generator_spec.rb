require "rails_helper"

RSpec.describe OtpCodeGenerator do
  describe "#call" do
    it "generates an 8 character code" do
      expect(subject.call.length).to eq(8)
    end

    it "only uses characters from Crockford's Base32 alphabet" do
      expect(subject.call).to match(/\A[0-9A-HJKMNP-TV-Z]{8}\z/)
    end

    it "generates a different code each time" do
      expect(subject.call).not_to eq(subject.call)
    end
  end

  describe ".matches?" do
    it "matches when the entered code is identical" do
      expect(described_class.matches?(entered_code: "ABCD2345", stored_code: "ABCD2345")).to be(true)
    end

    it "matches when the entered code is in lower case" do
      expect(described_class.matches?(entered_code: "abcd2345", stored_code: "ABCD2345")).to be(true)
    end

    {
      "O" => "0",
      "o" => "0",
      "I" => "1",
      "i" => "1",
      "L" => "1",
      "l" => "1",
    }.each do |typed, digit|
      it "treats '#{typed}' as '#{digit}'" do
        entered = "#{typed}BCD2345"
        stored = "#{digit}BCD2345"
        expect(described_class.matches?(entered_code: entered, stored_code: stored)).to be(true)
      end
    end

    it "does not match a different code" do
      expect(described_class.matches?(entered_code: "WXYZ6789", stored_code: "ABCD2345")).to be(false)
    end

    it "does not match a nil entered code" do
      expect(described_class.matches?(entered_code: nil, stored_code: "ABCD2345")).to be(false)
    end
  end
end
