require "rails_helper"

RSpec.describe Users::FindOrCreateFromTeacherAuth do
  subject(:service) do
    described_class.new(
      email: email,
      full_name: full_name,
      previous_names: previous_names,
      trn: trn,
    )
  end

  let(:email) { "teacher@example.com" }
  let(:full_name) { "Jane Smith" }
  let(:previous_names) { ["Jane Doe"] }
  let(:trn) { "1234567" }

  describe "#call" do
    context "when user does not exist" do
      it "creates a new user with the provided attributes" do
        expect { service.call }.to change(User, :count).by(1)

        user = User.last
        expect(user.email).to eq(email.downcase)
        expect(user.full_name).to eq(full_name)
        expect(user.previous_names).to eq(previous_names)
        expect(user.trn).to eq(trn)
        expect(user.ecf_id).to be_present
      end

      it "returns the created user" do
        user = service.call
        expect(user).to be_a(User)
        expect(user).to be_persisted
      end
    end

    context "when user already exists" do
      let!(:existing_user) { create(:user, email: email.downcase) }

      it "does not create a new user" do
        expect { service.call }.not_to change(User, :count)
      end

      it "updates the existing user with new attributes" do
        user = service.call

        expect(user.id).to eq(existing_user.id)
        expect(user.full_name).to eq(full_name)
        expect(user.previous_names).to eq(previous_names)
        expect(user.trn).to eq(trn)
      end

      it "returns the updated user" do
        user = service.call
        expect(user).to eq(existing_user.reload)
      end
    end

    context "when email has mixed case" do
      let(:email) { "Teacher@Example.COM" }

      it "downcases the email when finding/creating" do
        user = service.call
        expect(user.email).to eq("teacher@example.com")
      end
    end

    context "when user already has ecf_id" do
      let(:existing_ecf_id) { SecureRandom.uuid }

      before do
        create(:user, email: email.downcase, ecf_id: existing_ecf_id)
      end

      it "does not overwrite the existing ecf_id" do
        user = service.call
        expect(user.ecf_id).to eq(existing_ecf_id)
      end
    end
  end
end
