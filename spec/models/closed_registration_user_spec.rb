require "rails_helper"

RSpec.describe ClosedRegistrationUser do
  describe "email" do
    subject { ClosedRegistrationUser.new(email: "UPPER.CASE@example.example  ").tap(&:valid?) }

    it { is_expected.to have_attributes email: "upper.case@example.example" }
  end
end
