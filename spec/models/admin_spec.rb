require "rails_helper"

RSpec.describe Admin, type: :model do
  describe "validation" do
    describe "full_name" do
      it { is_expected.to validate_presence_of(:full_name).with_message("Enter a full name") }
      it { is_expected.to validate_length_of(:full_name).is_at_most(64).with_message("Full name must be shorter than 64 characters") }
    end

    describe "email" do
      it { is_expected.to validate_presence_of(:email).with_message("Enter an email address") }
      it { is_expected.to validate_length_of(:email).is_at_most(64).with_message("Email must be shorter than 64 characters") }
    end
  end

  describe ".active" do
    let(:active_admin) { create(:super_admin) }

    before do
      active_admin
      create(:super_admin, :archived)
    end

    it "returns only admins that are not archived" do
      expect(Admin.active).to contain_exactly(active_admin)
    end
  end

  describe ".archived" do
    let(:archived_admin) { create(:super_admin, :archived) }

    before do
      archived_admin
      create(:super_admin)
    end

    it "returns only admins that are not archived" do
      expect(Admin.archived).to contain_exactly(archived_admin)
    end
  end

  describe "defaults" do
    specify "super_admin defaults to false" do
      expect(Admin.new.super_admin?).to be false
    end
  end

  describe "#name_with_email" do
    subject { admin.name_with_email }

    let(:admin) { build(:admin) }

    it { is_expected.to eq("#{admin.full_name} (#{admin.email})") }

    context "when the admin is archived" do
      let(:admin) { build(:admin, :archived) }

      it { is_expected.to eq("#{admin.full_name} (#{admin.email}) (archived)") }
    end
  end

  describe "#archive!" do
    let(:admin) { create(:admin) }

    it "archives the admin" do
      expect { admin.archive! }.to change(admin, :archived_at).from(nil).to be_present
    end
  end
end
