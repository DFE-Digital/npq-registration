require "rails_helper"

RSpec.describe Forms::CookiePreferences, type: :model do
  describe "validations" do
    it { is_expected.to validate_inclusion_of(:consent).in_array(Forms::CookiePreferences::VALID_CONSENT_OPTIONS) }

    it "ensures return_path starts with '/' to prevent external redirects" do
      subject.return_path = "https://example.com"
      subject.valid?
      expect(subject.errors[:return_path]).to be_present

      subject.return_path = "/foo"
      subject.valid?
      expect(subject.errors[:return_path]).to be_blank
    end
  end
end
