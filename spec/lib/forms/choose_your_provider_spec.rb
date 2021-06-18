require "rails_helper"

RSpec.describe Forms::ChooseYourProvider, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:lead_provider_id) }

    it "course for lead_provider_id must exist" do
      subject.lead_provider_id = 0
      subject.valid?
      expect(subject.errors[:lead_provider_id]).to be_present

      subject.lead_provider_id = LeadProvider.first.id
      subject.valid?
      expect(subject.errors[:lead_provider_id]).to be_blank
    end
  end
end
