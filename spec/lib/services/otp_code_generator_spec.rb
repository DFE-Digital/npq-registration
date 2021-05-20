require "rails_helper"

RSpec.describe Services::OtpCodeGenerator do
  describe "#call" do
    it "generates a 6 digit code" do
      expect(subject.call).to match(/\d{6}/)
    end
  end
end
