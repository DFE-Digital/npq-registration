require "rails_helper"

RSpec.describe Forms::ContactDetails, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:email) }

    it "validates email addresses" do
      subject.email = "notvalid@example"
      subject.valid?
      expect(subject.errors[:email]).to be_present

      subject.email = "valid@example.com"
      subject.valid?
      expect(subject.errors[:email]).not_to be_present
    end
  end

  describe "#previous_step" do
    let(:wizard) { RegistrationWizard.new(current_step: :contact_details, store: store) }

    before do
      subject.wizard = wizard
    end

    context "when name has not changed" do
      let(:store) { { "changed_name" => "no" } }

      it "return name_changes" do
        expect(subject.previous_step).to eql(:name_changes)
      end
    end

    context "when name has been updated" do
      let(:store) { { "updated_name" => "yes" } }

      it "returns updated_name" do
        expect(subject.previous_step).to eql(:updated_name)
      end
    end

    context "when using old name" do
      let(:store) { { "name_not_updated_action" => "use_old_name" } }

      it "returns not_updated_name" do
        expect(subject.previous_step).to eql(:not_updated_name)
      end
    end
  end
end
