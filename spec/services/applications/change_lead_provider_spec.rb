# frozen_string_literal: true

require "rails_helper"

RSpec.describe Applications::ChangeLeadProvider, :with_cohorts, type: :model do
  subject(:service) { described_class.new(application:, lead_provider_id:) }

  let(:application) { create(:application, cohort:) }
  let(:cohort) { create(:cohort, :current) }
  let(:lead_provider_id) { LeadProvider.for(course: application.course).last.id }

  describe "validation" do
    it { is_expected.to validate_presence_of :application }
    it { is_expected.to validate_presence_of(:lead_provider_id).with_message "Choose a provider" }

    context "when lead_provider_id is not different to the current lead provider" do
      let(:lead_provider_id) { application.lead_provider.id }

      it { is_expected.not_to be_valid }
    end

    context "when the lead_provider_id is different" do
      let(:lead_provider_id) { LeadProvider.for(course: application.course).last.id }

      it { is_expected.to be_valid }
    end
  end

  describe "#change_lead_provider" do
    subject { service.change_lead_provider }

    context "when lead_provider_id is not different to the current lead provider" do
      let(:lead_provider_id) { application.lead_provider.id }

      it { is_expected.to be false }
    end

    context "when lead_provider_id is different to the current lead provider" do
      it "changes the lead provider" do
        expect { subject }.to change(application, :lead_provider_id).to(lead_provider_id)
      end

      it { is_expected.to be true }
    end
  end

  describe "#lead_provider_options" do
    let(:lead_providers_offering_course) { LeadProvider.where(name: ["Best Practice Network", "LLSE"]).map(&:name) }
    let(:cohort) { create(:cohort, :next, :unfunded) }

    before do
      course_cohort = create(:course_cohort, course: application.course, cohort:)
      lead_providers_offering_course.each do |lead_provider_name|
        create(:course_cohort_provider, course_cohort:, lead_provider: LeadProvider.find_by(name: lead_provider_name))
      end
    end

    it "includes all lead providers except the current lead provider" do
      expect(service.lead_provider_options).to match_array(
        LeadProvider.where.not(id: application.lead_provider.id).map { |lp| an_object_having_attributes(id: lp.id, name: lp.name) },
      )
    end

    it "does not have a description for lead providers that offering the course" do
      expect(
        service.lead_provider_options.select { |option| lead_providers_offering_course.include?(option.name) }.map(&:description),
      ).to all(be_nil)
    end

    it "includes a description for lead providers that are not offering the course" do
      expect(
        service.lead_provider_options.reject { |option| lead_providers_offering_course.include?(option.name) }.map(&:description),
      ).to all(eq "This provider is not offering npq-senior-leadership for the chosen cohort")
    end
  end
end
