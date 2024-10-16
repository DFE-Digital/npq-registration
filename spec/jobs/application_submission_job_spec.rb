require "rails_helper"

RSpec.describe ApplicationSubmissionJob do
  include CourseHelper
  subject { described_class.new(user:, email_template: "b8b53310-fa6f-4587-972a-f3f3c6e0892e") }

  describe "#perform" do
    let!(:application) { create(:application, user:, school:, ecf_id: nil) }
    let(:user) { create(:user, :with_get_an_identity_id, ecf_id: nil) }
    let(:school) { create(:school) }

    it "calls correct services" do
      user_finder_double = instance_double(Ecf::EcfUserFinder, call: nil)
      user_creator_double = instance_double(Ecf::EcfUserCreator, call: nil)
      profile_creator_double = instance_double(Ecf::NpqProfileCreator, call: nil)

      expect(Ecf::EcfUserFinder).to receive(:new).with(user:).and_return(user_finder_double)
      expect(Ecf::EcfUserCreator).to receive(:new).with(user:).and_return(user_creator_double)
      expect(Ecf::NpqProfileCreator).to receive(:new).with(application:).and_return(profile_creator_double)

      subject.perform_now

      expect(user_creator_double).to have_received(:call)
      expect(profile_creator_double).to have_received(:call)
    end

    it "sends submission email" do
      user_finder_double = instance_double(Ecf::EcfUserFinder, call: nil)
      user_creator_double = instance_double(Ecf::EcfUserCreator, call: nil)
      profile_creator_double = instance_double(Ecf::NpqProfileCreator, call: nil)

      expect(Ecf::EcfUserFinder).to receive(:new).with(user:).and_return(user_finder_double)
      expect(Ecf::EcfUserCreator).to receive(:new).and_return(user_creator_double)
      expect(Ecf::NpqProfileCreator).to receive(:new).and_return(profile_creator_double)

      localised_course_name = localise_sentence_embedded_course_name(application.course)

      allow(ApplicationSubmissionMailer).to receive(:application_submitted_mail).and_call_original
      expect(ApplicationSubmissionMailer).to receive(:application_submitted_mail).with(
        "b8b53310-fa6f-4587-972a-f3f3c6e0892e",
        amount: nil,
        to: user.email,
        full_name: user.full_name,
        provider_name: application.lead_provider.name,
        course_name: localised_course_name,
      )

      subject.perform_now
    end

    context "when user already exists in ecf and npq" do
      let(:user) { create(:user, ecf_id: "6c693c6b-6103-4afb-9315-af0d4b314c6c") }

      it "calls correct servivces" do
        instance_double(Ecf::EcfUserCreator)
        profile_creator_double = instance_double(Ecf::NpqProfileCreator, call: nil)
        ecf_user = instance_double(External::EcfAPI::Npq::User)

        expect(Ecf::EcfUserCreator).not_to receive(:new)
        expect(Ecf::NpqProfileCreator).to receive(:new).with(application:).and_return(profile_creator_double)
        expect(External::EcfAPI::Npq::User).to receive(:find).and_return([ecf_user])
        expect(ecf_user).to receive(:update).with({
          email: user.email,
          full_name: user.full_name,
          get_an_identity_id: user.get_an_identity_id,
        })

        subject.perform_now

        expect(profile_creator_double).to have_received(:call)
      end
    end

    context "when user already exists in ecf but not npq" do
      let(:user) { create(:user, ecf_id: nil) }
      let(:ecf_user) { External::EcfAPI::User.new(email: user.email, id: "15e62e53-239b-4688-bf8c-8a8f879a220c") }

      it "calls correct services" do
        user_finder_double = instance_double(Ecf::EcfUserFinder, call: ecf_user)
        profile_creator_double = instance_double(Ecf::NpqProfileCreator, call: nil)
        ecf_user = instance_double(External::EcfAPI::Npq::User)

        expect(Ecf::EcfUserFinder).to receive(:new).with(user:).and_return(user_finder_double)
        expect(Ecf::EcfUserCreator).not_to receive(:new)
        expect(Ecf::NpqProfileCreator).to receive(:new).with(application:).and_return(profile_creator_double)
        expect(External::EcfAPI::Npq::User).to receive(:find).and_return([ecf_user])
        expect(ecf_user).to receive(:update).with({
          email: user.email,
          full_name: user.full_name,
          get_an_identity_id: user.get_an_identity_id,
        })

        subject.perform_now

        expect(user.reload.ecf_id).to eql("15e62e53-239b-4688-bf8c-8a8f879a220c")

        expect(user_finder_double).to have_received(:call)
        expect(profile_creator_double).to have_received(:call)
      end
    end

    context "when applications already exists in ecf" do
      let(:user) { create(:user, ecf_id: "61363b02-73c7-4488-8832-ee4825070a59") }
      let(:application) { create(:application, user:, ecf_id: "441ea49f-824e-45b7-98d6-0691209a0b90", school:) }

      it "calls correct servivces" do
        instance_double(Ecf::EcfUserCreator)
        instance_double(Ecf::NpqProfileCreator, call: nil)
        ecf_user = instance_double(External::EcfAPI::Npq::User)

        expect(Ecf::EcfUserCreator).not_to receive(:new)
        expect(Ecf::NpqProfileCreator).not_to receive(:new)
        expect(External::EcfAPI::Npq::User).to receive(:find).and_return([ecf_user])
        expect(ecf_user).to receive(:update).with({
          email: user.email,
          full_name: user.full_name,
          get_an_identity_id: user.get_an_identity_id,
        })

        subject.perform_now
      end
    end

    context "when ecf_api_disabled flag is toggled on" do
      before { Flipper.enable(Feature::ECF_API_DISABLED) }

      it "returns nil" do
        expect(subject.perform_now).to be_nil
      end
    end
  end
end
