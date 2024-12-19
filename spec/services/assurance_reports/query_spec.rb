# frozen_string_literal: true

require "rails_helper"

RSpec.describe AssuranceReports::Query do
  subject(:query) { described_class.new(statement) }

  before do
    declaration && other_declaration && other_lead_provider_declaration
  end

  let(:assurance_report)    { query.declarations.first }
  let(:lead_provider)       { create(:lead_provider) }
  let(:other_lead_provider) { create(:lead_provider) }
  let(:statement)           { create(:statement, lead_provider:) }
  let(:training_status)     { :active }

  let :declaration do
    travel_to(statement.deadline_date) do
      create(:declaration, lead_provider:) do |declaration|
        declaration.application.update!(training_status:)
        create(:statement_item, statement:, declaration:)
      end
    end
  end

  let :other_statement do
    create(:statement, :next_period, lead_provider:, deadline_date: statement.deadline_date + 1.day)
  end

  let :other_declaration do
    travel_to(other_statement.deadline_date) do
      create(:declaration, lead_provider:) do |declaration|
        create(:statement_item, statement: other_statement, declaration:)
      end
    end
  end

  let :other_lead_provider_statement do
    create(:statement, lead_provider: other_lead_provider,
                       deadline_date: statement.deadline_date + 1.day)
  end

  let :other_lead_provider_declaration do
    travel_to(other_lead_provider_statement.deadline_date) do
      create(:declaration, lead_provider: other_lead_provider) do |declaration|
        create(:statement_item, statement: other_lead_provider_statement, declaration:)
      end
    end
  end

  describe "#declarations" do
    subject(:declarations) { query.declarations }

    it "includes the declaration" do
      expect(declarations).to eq([declaration])
    end

    describe "declaration attributes" do
      subject { declarations.first }

      it { is_expected.to have_attributes id: declaration.id }
      it { is_expected.to have_attributes participant_id: be_present }
      it { is_expected.to have_attributes participant_id: declaration.application.user.ecf_id }
      it { is_expected.to have_attributes participant_name: declaration.application.user.full_name }
      it { is_expected.to have_attributes trn: declaration.application.user.trn }
      it { is_expected.to have_attributes application_course_identifier: declaration.course_identifier }
      it { is_expected.to have_attributes eligible_for_funding: declaration.application.eligible_for_funding }
      it { is_expected.to have_attributes funded_place: declaration.application.funded_place }
      it { is_expected.to have_attributes npq_lead_provider_name: declaration.lead_provider.name }
      it { is_expected.to have_attributes npq_lead_provider_id: be_present }
      it { is_expected.to have_attributes npq_lead_provider_id: declaration.lead_provider.ecf_id }
      it { is_expected.to have_attributes school_urn: declaration.application.school.urn }
      it { is_expected.to have_attributes school_name: declaration.application.school.name }
      it { is_expected.to have_attributes training_status: declaration.application.training_status }
      it { is_expected.to have_attributes training_status_reason: be_nil }
      it { is_expected.to have_attributes declaration_id: be_present }
      it { is_expected.to have_attributes declaration_id: declaration.ecf_id }
      it { is_expected.to have_attributes declaration_status: declaration.statement_items.first.state }
      it { is_expected.to have_attributes declaration_type: declaration.declaration_type }
      it { is_expected.to have_attributes declaration_date: declaration.declaration_date }
      it { is_expected.to have_attributes declaration_created_at: declaration.created_at }
      it { is_expected.to have_attributes statement_id: be_present }
      it { is_expected.to have_attributes statement_id: statement.ecf_id }
      it { is_expected.to have_attributes statement_month: statement.month }
      it { is_expected.to have_attributes statement_year: statement.year }
      it { is_expected.to have_attributes targeted_delivery_funding: declaration.application.targeted_delivery_funding_eligibility }

      context "when last status update was 'withdrawn'" do
        let(:training_status) { :withdrawn }

        before do
          create(:application_state, :withdrawn, application: declaration.application,
                                                 lead_provider: declaration.lead_provider)
        end

        it { is_expected.to have_attributes training_status: "withdrawn" }
        it { is_expected.to have_attributes training_status_reason: "other" }

        context "with later second declaration for same lead provider" do
          before do
            statement = create(:statement, lead_provider:)

            travel_to(statement.deadline_date) do
              create(:declaration, lead_provider:) do |declaration|
                declaration.application.update! training_status: "withdrawn"

                create(:statement_item, statement:, declaration:)
                create(:application_state, :withdrawn, application: declaration.application,
                                                       lead_provider: declaration.lead_provider,
                                                       reason: "a different reason")
              end
            end
          end

          it { is_expected.to have_attributes training_status: "withdrawn" }
          it { is_expected.to have_attributes training_status_reason: "other" }
        end
      end

      context "when last status update was 'deferred'" do
        let(:training_status) { :deferred }

        before do
          create(:application_state, :deferred, application: declaration.application,
                                                lead_provider: declaration.lead_provider)
        end

        it { is_expected.to have_attributes training_status: "deferred" }
        it { is_expected.to have_attributes training_status_reason: be_nil }
      end
    end
  end
end
