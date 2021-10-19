require "rails_helper"

RSpec.describe Services::HandleSubmissionForStore do
  let(:user) { create(:user, trn: nil) }
  let(:school) { create(:school) }

  let(:store) do
    {
      "confirmed_email" => user.email,
      "trn_verified" => false,
      "trn" => "12345",
      "course_id" => Course.all.sample.id,
      "institution_identifier" => "School-#{school.urn}",
      "lead_provider_id" => LeadProvider.all.sample.id,
    }
  end

  subject { described_class.new(store: store) }

  describe "#call" do
    context "when entered trn is shorter than 7 characters" do
      it "pads by prefixing zeros to 7 characters" do
        subject.call

        expect(user.reload.trn).to eql("0012345")
      end
    end
  end
end
