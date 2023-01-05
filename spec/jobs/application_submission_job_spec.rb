require "rails_helper"

RSpec.describe ApplicationSubmissionJob do
  subject { described_class.new(user:) }

  describe "#perform" do
    let(:application) { create(:application, user:, school:) }
    let(:user) { create(:user) }
    let(:school) { create(:school) }

    before do
      application
    end

    it "calls correct services" do
      user_finder_double = instance_double(Services::Ecf::EcfUserFinder, call: nil)
      user_creator_double = instance_double(Services::Ecf::EcfUserCreator, call: nil)
      profile_creator_double = instance_double(Services::Ecf::NpqProfileCreator, call: nil)

      expect(Services::Ecf::EcfUserFinder).to receive(:new).with(user:).and_return(user_finder_double)
      expect(Services::Ecf::EcfUserCreator).to receive(:new).with(user:).and_return(user_creator_double)
      expect(Services::Ecf::NpqProfileCreator).to receive(:new).with(application:).and_return(profile_creator_double)

      subject.perform_now

      expect(user_creator_double).to have_received(:call)
      expect(profile_creator_double).to have_received(:call)
    end

    it "sends submission email" do
      user_finder_double = instance_double(Services::Ecf::EcfUserFinder, call: nil)
      user_creator_double = instance_double(Services::Ecf::EcfUserCreator, call: nil)
      profile_creator_double = instance_double(Services::Ecf::NpqProfileCreator, call: nil)

      expect(Services::Ecf::EcfUserFinder).to receive(:new).with(user:).and_return(user_finder_double)
      expect(Services::Ecf::EcfUserCreator).to receive(:new).and_return(user_creator_double)
      expect(Services::Ecf::NpqProfileCreator).to receive(:new).and_return(profile_creator_double)

      allow(ApplicationSubmissionMailer).to receive(:application_submitted_mail).and_call_original
      expect(ApplicationSubmissionMailer).to receive(:application_submitted_mail).with(
        to: user.email,
        full_name: user.full_name,
        provider_name: application.lead_provider.name,
        course_name: application.course.name,
      )

      subject.perform_now
    end

    context "when user already exists in ecf and npq" do
      let(:user) { create(:user, ecf_id: "123") }

      it "calls correct servivces" do
        instance_double(Services::Ecf::EcfUserCreator)
        profile_creator_double = instance_double(Services::Ecf::NpqProfileCreator, call: nil)

        expect(Services::Ecf::EcfUserCreator).not_to receive(:new)
        expect(Services::Ecf::NpqProfileCreator).to receive(:new).with(application:).and_return(profile_creator_double)

        subject.perform_now

        expect(profile_creator_double).to have_received(:call)
      end
    end

    context "when user already exists in ecf but not npq" do
      let(:user) { create(:user) }
      let(:ecf_user) { EcfApi::User.new(email: user.email, id: "123") }

      it "calls correct services" do
        user_finder_double = instance_double(Services::Ecf::EcfUserFinder, call: ecf_user)
        profile_creator_double = instance_double(Services::Ecf::NpqProfileCreator, call: nil)

        expect(Services::Ecf::EcfUserFinder).to receive(:new).with(user:).and_return(user_finder_double)
        expect(Services::Ecf::EcfUserCreator).not_to receive(:new)
        expect(Services::Ecf::NpqProfileCreator).to receive(:new).with(application:).and_return(profile_creator_double)

        subject.perform_now

        expect(user.reload.ecf_id).to eql("123")

        expect(user_finder_double).to have_received(:call)
        expect(profile_creator_double).to have_received(:call)
      end
    end

    context "when applications already exists in ecf" do
      let(:user) { create(:user, ecf_id: "123") }
      let(:application) { create(:application, user:, ecf_id: "456", school:) }

      it "calls correct servivces" do
        instance_double(Services::Ecf::EcfUserCreator)
        instance_double(Services::Ecf::NpqProfileCreator, call: nil)

        expect(Services::Ecf::EcfUserCreator).not_to receive(:new)
        expect(Services::Ecf::NpqProfileCreator).not_to receive(:new)

        subject.perform_now
      end
    end
  end
end
