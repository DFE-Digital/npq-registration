require "rails_helper"

RSpec.describe Users::FindOrCreateFromTeacherAuth do
  subject { described_class.new(provider_data:, feature_flag_id:).call }

  let(:uid) { "urn:fdc:gov.uk:2022:#{SecureRandom.alphanumeric(43)}" }
  let(:feature_flag_id) { SecureRandom.uuid }
  let(:email) { "user@example.com" }
  let(:trn) { "1234567" }
  let(:verified_name) { %w[Test User] }
  let(:api_previous_names) { [] }

  let(:provider_data) do
    OpenStruct.new({
      uid:,
      credentials: OpenStruct.new({
        token: "123456",
      }),
      info: OpenStruct.new({
        email:,
      }),
      extra: OpenStruct.new({
        raw_info: OpenStruct.new({
          trn:,
          verified_name:,
          verified_date_of_birth: "1990-01-01",
        }),
      }),
    })
  end

  before do
    create(:user, trn:, trn_verified: true, archived_at: 1.day.ago)

    stub_request(:get, "#{ENV['TRS_API_URL']}/v3/person")
      .with(
        headers: {
          "Authorization" => "Bearer 123456",
          "X-Api-Version" => "Next",
        },
        query: { "include" => "PreviousNames" },
      )
      .to_return(status: 200, body: { previousNames: api_previous_names }.to_json)
  end

  context "when the TRN matches a verified TRN on one user" do
    let(:user) { create(:user, trn:, trn_verified: true) }

    before { user }

    it "sets the uid and provider on the user" do
      subject
      expect(user.reload).to have_attributes(uid:, provider: "teacher_auth")
    end

    it "returns the user" do
      expect(subject).to eq(user)
    end

    context "when user's details have updated" do
      it "updates the user" do
        subject
        expect(user.reload).to have_attributes(email:, full_name: verified_name.join(" "))
      end
    end

    describe "previous names handling" do
      context "when the API returns no previous names" do
        let(:api_previous_names) { [] }

        it "stores an empty array for previous_names on the user" do
          subject
          expect(user.reload.previous_names).to eq([])
        end
      end

      context "when the API returns one previous name" do
        let(:api_previous_names) do
          [{ "firstName" => "Sarah", "lastName" => "Johnson" }]
        end

        it "stores the previous name on the user" do
          subject
          expect(user.reload.previous_names).to eq(["Sarah Johnson"])
        end
      end

      context "when the API returns multiple previous names" do
        let(:api_previous_names) do
          [
            { "firstName" => "Sarah", "lastName" => "Johnson" },
            { "firstName" => "Sarah", "middleName" => "Ann", "lastName" => "Williams" },
          ]
        end

        it "stores all previous names on the user" do
          subject
          expect(user.reload.previous_names).to eq([
            "Sarah Johnson",
            "Sarah Ann Williams",
          ])
        end
      end

      context "when the user already has previous_names" do
        let(:user) { create(:user, trn:, trn_verified: true, previous_names: ["Old Name"]) }
        let(:api_previous_names) do
          [{ "firstName" => "Sarah", "lastName" => "Johnson" }]
        end

        it "replaces old previous_names with new data from API" do
          subject
          expect(user.reload.previous_names).to eq(["Sarah Johnson"])
        end
      end
    end
  end

  context "when the TRN matches a verified TRN on more than one user" do
    let(:most_recently_updated_user) { create(:user, trn:, trn_verified: true) }
    let(:older_user) { create(:user, trn:, trn_verified: true, updated_at: 2.days.ago) }
    let(:application) { create(:application, user: older_user) }

    before do
      travel_to(1.day.ago) { most_recently_updated_user }
      travel_to(2.days.ago) { application }
    end

    it "sets the uid and provider on the most recently updated user" do
      subject
      expect(most_recently_updated_user.reload).to have_attributes(uid:, provider: "teacher_auth")
    end

    it "moves applications to the most recently updated user" do
      subject
      expect(application.reload.user).to eq(most_recently_updated_user)
    end

    it "archives the other users" do
      subject
      expect(older_user.reload).to be_archived
    end

    it "creates participant ID records" do
      subject
      expect(most_recently_updated_user.participant_id_changes.find_by(from_participant_id: older_user.ecf_id, to_participant_id: most_recently_updated_user.ecf_id)).to be_present
    end

    it "returns the most recently updated user" do
      expect(subject).to eq(most_recently_updated_user)
    end

    context "when user's details have updated" do
      it "updates the user" do
        subject
        expect(most_recently_updated_user.reload).to have_attributes(email:, full_name: verified_name.join(" "))
      end
    end

    context "when the API returns previous names" do
      let(:api_previous_names) do
        [{ "firstName" => "Sarah", "lastName" => "Johnson" }]
      end

      it "stores previous_names on the kept user" do
        subject
        expect(most_recently_updated_user.reload.previous_names).to eq(["Sarah Johnson"])
      end
    end
  end

  shared_examples "logging in using provider and UID" do
    context "when a user exists with the same provider and UID" do
      let(:existing_user) { create(:user, :with_teacher_auth, email: "oldemail@example.com", uid:) }

      before { existing_user }

      context "when users details have updated" do
        it "updates the user" do
          subject
          expect(existing_user.reload).to have_attributes(email:, full_name: verified_name.join(" "))
        end
      end

      context "when the TRN is different" do
        let(:existing_user) { create(:user, :with_teacher_auth, email:, uid:, trn: "2345678") }

        it "updates the verified TRN on the user" do
          subject
          expect(existing_user.reload).to have_attributes(trn:, trn_verified: true, trn_auto_verified: true)
        end
      end

      context "when the existing user already has the incoming email" do
        let(:existing_user) { create(:user, :with_teacher_auth, email:, uid:) }

        it "does not archive the existing user" do
          subject
          expect(existing_user.reload).to have_attributes(email:, archived_at: nil, archived_email: nil)
        end
      end

      context "when the email clashes with a different existing user" do
        let!(:clashing_user) { create(:user, :with_get_an_identity_id, email:) }

        it "blanks the clashing user's email and updates the matched user" do
          expect { subject }.not_to raise_error
          expect(clashing_user.reload).to have_attributes(email: nil, archived_email: email)
          expect(clashing_user.archived_at).to be_present
          expect(existing_user.reload).to have_attributes(email:, archived_at: nil)
        end
      end

      context "when the API returns previous names" do
        let(:api_previous_names) do
          [{ "firstName" => "Sarah", "lastName" => "Johnson" }]
        end

        it "updates previous_names on the user" do
          subject
          expect(existing_user.reload.previous_names).to eq(["Sarah Johnson"])
        end
      end

      context "when the user already has different previous_names" do
        let(:existing_user) do
          create(:user, :with_teacher_auth, email: "oldemail@example.com", uid:,
                                            previous_names: ["Old Previous Name"])
        end
        let(:api_previous_names) do
          [{ "firstName" => "Sarah", "lastName" => "Johnson" }]
        end

        it "replaces old previous_names with new API data" do
          subject
          expect(existing_user.reload.previous_names).to eq(["Sarah Johnson"])
        end
      end
    end

    context "when no user exists with the same provider and UID" do
      it "creates a new user" do
        subject
        expect(User.find_by(provider: "teacher_auth", uid:)).to have_attributes(
          email:,
          trn:,
          trn_verified: true,
          trn_auto_verified: true,
          full_name: verified_name.join(" "),
          date_of_birth: Date.parse("1990-01-01"),
          feature_flag_id:,
        )
      end

      context "when the email clashes with a different existing user" do
        let!(:clashing_user) { create(:user, :with_get_an_identity_id, email:) }

        it "blanks the clashing user's email and creates the new user" do
          expect { subject }.not_to raise_error
          expect(clashing_user.reload).to have_attributes(email: nil, archived_email: email)
          expect(clashing_user.archived_at).to be_present
          expect(User.find_by(provider: "teacher_auth", uid:).email).to eq(email)
        end

        it "does not move applications from the clashing user" do
          application = create(:application, user: clashing_user)
          subject
          expect(application.reload.user).to eq(clashing_user)
        end

        it "sends a Sentry notification" do
          expect(Sentry).to receive(:capture_message).with(
            "Blanked email on the user due to reuse when used by a later participant",
            hash_including(extra: { ecf_id: clashing_user.ecf_id }),
          )
          subject
        end
      end

      context "when the API returns no previous names" do
        let(:api_previous_names) { [] }

        it "creates the user with an empty previous_names array" do
          subject
          created_user = User.find_by(provider: "teacher_auth", uid:)
          expect(created_user.previous_names).to eq([])
        end
      end

      context "when the API returns previous names" do
        let(:api_previous_names) do
          [
            { "firstName" => "Sarah", "lastName" => "Johnson" },
            { "firstName" => "Sarah", "middleName" => "Ann", "lastName" => "Williams" },
          ]
        end

        it "creates the user with previous_names from API" do
          subject
          created_user = User.find_by(provider: "teacher_auth", uid:)
          expect(created_user.previous_names).to eq([
            "Sarah Johnson",
            "Sarah Ann Williams",
          ])
        end
      end
    end
  end

  context "when the TRN doesn't match a user" do
    it_behaves_like "logging in using provider and UID"
  end

  context "when no TRN is specified" do
    let(:trn) { nil }

    it_behaves_like "logging in using provider and UID"
  end
end
