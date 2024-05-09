require "rails_helper"

RSpec.describe Events::ApplicationAcceptance do
  let(:application) { FactoryBot.create(:application) }

  let(:user) { application.user }
  let(:school) { application.school }
  let(:private_childcare_provider) { application.private_childcare_provider }
  let(:cohort) { application.cohort }
  let(:course) { application.course }
  let(:lead_provider) { application.lead_provider }

  describe "#initialize" do
    let(:application_acceptance) { Events::ApplicationAcceptance.new(application:, user:, school:, private_childcare_provider:, cohort:, course:, lead_provider:) }

    it("correctly assigns the user") { expect(application_acceptance.user).to eq(application.user) }
    it("correctly assigns the school") { expect(application_acceptance.school).to eq(application.school) }
    it("correctly assigns the cohort") { expect(application_acceptance.cohort).to eq(application.cohort) }
    it("correctly assigns the course") { expect(application_acceptance.course).to eq(application.course) }
    it("correctly assigns the lead_provider") { expect(application_acceptance.lead_provider).to eq(application.lead_provider) }

    it("doesn't assign the private childcare provider") { expect(application_acceptance.private_childcare_provider).to be_nil }
  end

  describe "#create_event" do
    let(:application_acceptance) { Events::ApplicationAcceptance.new(application:, user:, school:, private_childcare_provider:, cohort:, course:, lead_provider:) }

    it "creates one event record" do
      expect { application_acceptance.create_event }.to change(Event, :count).by(1)
    end

    it "creates the event record with the right values" do
      event = application_acceptance.create_event

      expect(event.user).to eql(user)
      expect(event.school).to eql(school)
      expect(event.cohort).to eql(cohort)
      expect(event.course).to eql(course)
      expect(event.lead_provider).to eql(lead_provider)
    end

    it "sets application type to 'Application accepted'" do
      event = application_acceptance.create_event

      expect(event.event_type).to eql("Application accepted")
    end
  end

  describe "#title" do
    let(:title) { nil }
    let(:application_acceptance) { Events::ApplicationAcceptance.new(title:, application:, user:, school:, private_childcare_provider:, cohort:, course:, lead_provider:) }

    it "defaults to 'Application [id] accepted" do
      expect(application_acceptance.title).to eql("Application #{application.id} accepted")
    end

    context "when title is overridden" do
      let(:title) { "New title" }

      it "uses the supplied title text" do
        expect(application_acceptance.title).to eql("New title")
      end
    end
  end

  describe "#byline" do
    let(:byline) { nil }
    let(:application_acceptance) { Events::ApplicationAcceptance.new(byline:, application:, user:, school:, private_childcare_provider:, cohort:, course:, lead_provider:) }

    it "defaults to 'Application [id] accepted" do
      expect(application_acceptance.title).to eql("Application #{application.id} accepted")
    end

    context "when byline is overridden" do
      it "uses the lead provider's name" do
        expect(application_acceptance.byline).to eql(lead_provider.name)
      end
    end
  end

  describe ".create_event_from_appliction" do
    before { allow(Events::ApplicationAcceptance).to receive(:new).and_call_original }

    it "calls .new with arguments from the event" do
      Events::ApplicationAcceptance.create_event_from_application(application)

      expect(Events::ApplicationAcceptance).to have_received(:new).with(application:, user:, school:, private_childcare_provider:, cohort:, course:, lead_provider:).once
    end
  end
end
