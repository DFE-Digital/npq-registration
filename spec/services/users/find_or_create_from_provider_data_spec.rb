require "rails_helper"

RSpec.describe Users::FindOrCreateFromProviderData do
  subject { described_class.new(provider_data:, feature_flag_id:).call }

  let(:provider_data_uid) { SecureRandom.uuid }
  let(:provider_data_date_of_birth_parsed) { Date.new(1980, 12, 13) }
  let(:provider_data_email) { "user@example.com" }
  let(:provider_data_trn) { "1234567" }
  let(:provider_data_name) { "John Doe" }
  let(:provider_data_preferred_name) { "Jonny D" }
  let(:provider_data_date_of_birth) { "1980-12-13" }
  let(:provider_data_first_name) { "John" }
  let(:provider_data_last_name) { "Doe" }
  let(:provider_data_trn_lookup_status) { "Found" }

  let(:provider_data) do
    OpenStruct.new({
      provider: "tra_openid_connect",
      uid: provider_data_uid,
      info: OpenStruct.new({
        date_of_birth: provider_data_date_of_birth_parsed,
        email: provider_data_email,
        email_verified: true,
        trn: provider_data_trn,
        name: provider_data_name,
        preferred_name: provider_data_preferred_name,
        provider_data_trn_lookup_status:,
      }),
      credentials: OpenStruct.new({
        "token" => SecureRandom.uuid,
        "expires_at" => 24.days.from_now.to_i,
        "expires" => true,
      }),
      extra: OpenStruct.new({
        raw_info: OpenStruct.new({
          "sub" => provider_data_uid,
          "email" => provider_data_email,
          "email_verified" => "True",
          "name" => provider_data_name,
          "preferred_name" => provider_data_preferred_name,
          "birthdate" => provider_data_date_of_birth,
          "trn" => provider_data_trn,
          "given_name" => provider_data_first_name,
          "family_name" => provider_data_last_name,
          "trn_lookup_status" => provider_data_trn_lookup_status,
        }),
      }),
    })
  end
  let(:feature_flag_id) { nil }

  shared_examples "a saved valid user with provider data assigned" do
    it "is persisted" do
      expect(subject).to be_persisted
    end

    it "is valid" do
      expect(subject).to be_valid
    end

    it "sets raw_tra_provider_data to the provider data" do
      expect(subject.raw_tra_provider_data).to eq JSON.parse(provider_data.to_json)
    end

    it "sets preferred_name to the preferred name" do
      expect(subject.preferred_name).to eq provider_data_preferred_name
    end

    it "sets full_name to the name" do
      expect(subject.full_name).to eq provider_data_name
    end

    context "when there is a date of birth" do
      it "sets date_of_birth" do
        expect(subject.date_of_birth).to eq provider_data_date_of_birth_parsed
      end
    end

    context "when there is no date of birth" do
      let(:provider_data_date_of_birth) { nil }

      it "does not set date_of_birth" do
        expect { subject }.not_to change(subject, :date_of_birth)
      end
    end

    context "when there is a TRN" do
      it "sets the TRN" do
        expect(subject.trn).to eq provider_data_trn
      end

      context "when trn_lookup_status is Found" do
        let(:provider_data_trn_lookup_status) { "Found" }

        it "sets trn_verified to true" do
          expect(subject.trn_verified).to be true
        end

        it "sets trn_lookup_status" do
          expect(subject.trn_lookup_status).to eq "Found"
        end
      end

      %w[None Pending Failed].each do |lookup_status|
        context "when trn_lookup_status is #{lookup_status}" do
          let(:provider_data_trn_lookup_status) { lookup_status }

          it "sets trn_verified to false" do
            expect(subject.trn_verified).to be false
          end

          it "sets trn_lookup_status" do
            expect(subject.trn_lookup_status).to eq provider_data_trn_lookup_status
          end
        end
      end
    end

    context "when there is no TRN" do
      let(:provider_data_trn) { nil }

      it "does not set the TRN" do
        expect { subject }.not_to change(subject, :trn)
      end

      it "does not change trn_verified" do
        expect { subject }.not_to change(subject, :trn_verified)
      end

      it "does not change trn_lookup_status" do
        expect { subject }.not_to change(subject, :trn_lookup_status)
      end
    end

    context "when a feature flag ID is provided" do
      let(:feature_flag_id) { SecureRandom.uuid }

      it "assigns the feature flag to the user" do
        expect(subject.feature_flag_id).to eq feature_flag_id
      end
    end
  end

  shared_examples "not changing TRN attributes on existing user when there is no TRN in the provider data" do
    context "when the user already has a verified TRN" do
      let(:provider_data_trn) { nil }

      before do
        existing_user.update!(trn: "2345678", trn_verified: true, trn_lookup_status: "Found")
      end

      it "does not change the TRN" do
        expect { subject }.not_to change(subject, :trn)
      end

      it "does not change trn_verified" do
        expect { subject }.not_to change(subject, :trn_verified)
      end

      it "does not change trn_lookup_status" do
        expect { subject }.not_to change(subject, :trn_lookup_status)
      end
    end
  end

  context "when the user with UID already exists" do
    let(:existing_user) do
      create(:user,
             :with_get_an_identity_id,
             uid: provider_data_uid,
             email: provider_data_email,
             trn: "0000000",
             trn_verified:,
             trn_lookup_status:)
    end

    let(:trn_verified) { false }
    let(:trn_lookup_status) { "Failed" }

    before { existing_user }

    it "updates the user's email" do
      expect(subject.email).to eq provider_data_email
    end

    it "sets updated_from_tra_at" do
      expect(subject.updated_from_tra_at).to be_present
    end

    it_behaves_like "a saved valid user with provider data assigned"
    it_behaves_like "not changing TRN attributes on existing user when there is no TRN in the provider data"

    context "when the user has a verified TRN" do
      let(:trn_verified) { true }

      context "when the provider data has a TRN that is the same as the user's current TRN" do
        let(:provider_data_trn) { "0000000" }

        context "when the trn_lookup_status is Found" do
          let(:trn_lookup_status) { "Found" }

          it "updates the trn_lookup_status to Found" do
            subject
            expect(existing_user.reload.trn_lookup_status).to eq("Found")
          end
        end

        context "when the trn_lookup_status is not Found" do
          let(:provider_data_trn_lookup_status) { "None" }

          it "does not change trn_verified" do
            subject
            expect(existing_user.reload.trn_verified).to be true
          end

          it "does not change trn_lookup_status" do
            subject
            expect(existing_user.reload.trn_lookup_status).to eq trn_lookup_status
          end
        end
      end

      context "when the provider data has a TRN that is different from the user's current TRN" do
        let(:provider_data_trn) { "2345678" }
        let(:provider_data_trn_lookup_status) { "None" }

        it "updates the TRN" do
          expect { subject }.to change { existing_user.reload.trn }.from("0000000").to("2345678")
        end

        it "updates trn_verified" do
          expect { subject }.to change { existing_user.reload.trn_verified }.from(true).to(false)
        end

        it "updates trn_lookup_status" do
          expect { subject }.to change { existing_user.reload.trn_lookup_status }.from("Failed").to("None")
        end
      end
    end

    context "when there is a clashing user with the same email" do
      let(:existing_user) { create(:user, :with_get_an_identity_id, uid: provider_data_uid, trn: "0000000") }

      let!(:clashing_user) { create(:user, email: provider_data_email) }

      it "archives the clashing user" do
        expect { subject }.to change { clashing_user.reload.archived? }.from(false).to(true)
      end

      it "sets updated_from_tra_at" do
        expect(subject.updated_from_tra_at).to be_present
      end

      it_behaves_like "a saved valid user with provider data assigned"
      it_behaves_like "not changing TRN attributes on existing user when there is no TRN in the provider data"
    end

    context "when the user is archived" do
      let(:existing_user) { create(:user, :archived, :with_get_an_identity_id, uid: provider_data_uid, trn: "0000000") }

      it "creates a new user with the UID and email" do
        expect(subject.uid).to eq provider_data_uid
        expect(subject.provider).to eq "tra_openid_connect"
        expect(subject.email).to eq provider_data_email
      end

      it_behaves_like "a saved valid user with provider data assigned"
      it_behaves_like "not changing TRN attributes on existing user when there is no TRN in the provider data"
    end
  end

  context "when user with UID does not exist" do
    context "when user with email already exists" do
      before { create(:user, email: provider_data_email, trn: "0000000") }

      it "assigns the UID" do
        expect(subject.uid).to eq provider_data_uid
        expect(subject.provider).to eq "tra_openid_connect"
      end

      it_behaves_like "a saved valid user with provider data assigned"

      context "when there is a clashing archived user with the same UID" do
        let!(:clashing_archived_user) { create(:user, :with_get_an_identity_id, :archived, uid: provider_data_uid, trn: "0000000") }

        it "sets the UID to nil on the archived user" do
          expect { subject }.to change { clashing_archived_user.reload.uid }.from(provider_data_uid).to(nil)
        end

        it "assigns the UID" do
          expect(subject.uid).to eq provider_data_uid
          expect(subject.provider).to eq "tra_openid_connect"
        end

        it_behaves_like "a saved valid user with provider data assigned"
      end
    end

    context "when user with email does not exist" do
      it "creates a new user with the UID and email" do
        expect(subject.uid).to eq provider_data_uid
        expect(subject.provider).to eq "tra_openid_connect"
        expect(subject.email).to eq provider_data_email
      end

      it "sets updated_from_tra_at" do
        expect(subject.updated_from_tra_at).to be_present
      end

      it_behaves_like "a saved valid user with provider data assigned"

      context "when there is a clashing archived user with the same UID" do
        let!(:clashing_archived_user) { create(:user, :with_get_an_identity_id, :archived, uid: provider_data_uid, trn: "0000000") }

        it "sets the UID to nil on the archived user" do
          expect { subject }.to change { clashing_archived_user.reload.uid }.from(provider_data_uid).to(nil)
        end

        it "assigns the UID to the existing user" do
          expect(subject.uid).to eq provider_data_uid
          expect(subject.provider).to eq "tra_openid_connect"
        end

        it_behaves_like "a saved valid user with provider data assigned"
      end
    end
  end

  context "when the provider email is cased differently but the same otherwise" do
    let(:provider_data_email) { "Foo@example.com" }
    let(:clashing_downcase_email) { "foo@example.com" }

    let!(:existing_user) { create(:user, email: clashing_downcase_email, trn: "0000000") }

    it "returns existing user" do
      expect(subject).to eq(existing_user)
    end
  end
end
