# frozen_string_literal: true

require "rails_helper"

RSpec.describe NpqSeparation::Admin::StatementDetailsComponent, type: :component do
  subject(:rendered) { render_inline instance }

  let(:instance) { described_class.new(statement:) }
  let(:cohort)        { build_stubbed(:cohort, :current) }
  let(:lead_provider) { build_stubbed(:lead_provider) }
  let(:statement)     { build_stubbed(:statement, lead_provider:, cohort:) }
  let(:application)   { build_stubbed(:application, :accepted, :eligible_for_funding, course:, lead_provider:) }
  let(:course)        { build_stubbed(:course, identifier: "npq-leading-teaching") }

  let(:declaration) do
    travel_to statement.deadline_date do
      build_stubbed(:declaration, :eligible, lead_provider:, application:)
    end
  end

  it { is_expected.to have_css "h4", text: "Totals" }
  it { is_expected.to have_css "p", text: "Output payment" }
  it { is_expected.to have_css "p", text: "Targeted delivery funding" }
  it { is_expected.to have_css "p", text: "Clawbacks" }
  it { is_expected.not_to have_css "p", text: "Service fee" }
  it { is_expected.to have_css "p", text: "Total net VAT" }
  it { is_expected.to have_css "ul li strong", text: "Output payment cut off date" }
  it { is_expected.to have_css "ul li strong", text: "Total starts" }
  it { is_expected.to have_css "ul li strong", text: "Total retained" }
  it { is_expected.to have_css "ul li strong", text: "Total completed" }
  it { is_expected.to have_css "ul li strong", text: "Total voids" }

  context "with targeted delivery funding" do
    before do
      allow(instance.calculator)
        .to receive_messages(show_targeted_delivery_funding?: false,
                             total_service_fees: 10.0)
    end

    it { is_expected.not_to have_css "p", text: "Targeted delivery funding" }
    it { is_expected.to have_css "p", text: "Service fee" }
  end
end
