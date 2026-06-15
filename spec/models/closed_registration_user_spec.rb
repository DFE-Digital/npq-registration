require "rails_helper"

RSpec.describe ClosedRegistrationUser do
  describe "normalisation" do
    subject { ClosedRegistrationUser.new(email: "UPPER.CASE@example.example  ").tap(&:valid?) }

    it { is_expected.to have_attributes email: "UPPER.CASE@example.example" }
  end

  describe "case insensitive lookup" do
    subject { ClosedRegistrationUser.find_by(email: "upper.case@example.example") }

    before { address }

    let(:address) { ClosedRegistrationUser.create(email: "UPPER.CASE@example.example  ") }

    it { is_expected.to eq address }
  end
end
