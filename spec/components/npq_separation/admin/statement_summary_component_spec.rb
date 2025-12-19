# frozen_string_literal: true

require "rails_helper"

RSpec.describe NpqSeparation::Admin::StatementSummaryComponent, type: :component do
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::NumberHelper

  subject(:rendered) { render_inline described_class.new(statement:) }

  let(:statement) { create(:statement) }
  let(:summary_list) { page.find(".govuk-summary-list") }
  let(:declaration_types) { [] }

  let(:calculator) do
    instance_double(
      Statements::SummaryCalculator,
      use_targeted_delivery_funding?: false,
      total_targeted_delivery_funding: 99,
      total_service_fees: 0,
      total_output_payment: 100.12,
      total_clawbacks: 50.34,
      total_adjustments: -10,
      total_payment: 39.78,
      total_starts: 1,
      total_retained: 2,
      total_completed: 3,
      total_voided: 4,
    )
  end

  let(:declarations_calculator) do
    instance_double(
      Statements::DeclarationsCalculator,
      expected_applications: [],
      received_declarations: [],
    )
  end

  let(:declarations_calculator) do
    instance_double(
      Statements::DeclarationsCalculator,
      expected_applications: [],
      total_expected_applications: 0,
      received_declarations: [],
    )
  end

  before do
    allow(::Statements::SummaryCalculator).to receive(:new).and_return(calculator)
    allow(::Statements::DeclarationsCalculator).to receive(:new).with(statement:).and_return(declarations_calculator)
  end

  it { is_expected.to have_text "Statement summary" }
  it { is_expected.to have_text "The output payment deadline is #{statement.deadline_date.to_fs(:govuk)}" }

  it "shows totals" do
    subject
    expect(summary_list).to have_summary_item("Voids", calculator.total_voided)
    expect(summary_list).to have_summary_item("Output payment", calculator.total_output_payment)
    expect(summary_list).to have_summary_item("Clawbacks", calculator.total_clawbacks)
    expect(summary_list).to have_summary_item("Adjustments", number_to_currency(calculator.total_adjustments))
  end

  it { is_expected.to have_link "View Voids", href: npq_separation_admin_finance_voided_index_path(statement) }

  context "when link_to_voids is false" do
    subject(:rendered) { render_inline described_class.new(statement:, link_to_voids: false) }

    it { is_expected.not_to have_link "View Voids", href: npq_separation_admin_finance_voided_index_path(statement) }
  end

  context "without targeted delivery funding" do
    it { is_expected.not_to have_text "Targeted delivery funding" }
  end

  context "with targeted delivery funding" do
    before do
      allow(calculator).to receive(:use_targeted_delivery_funding?).and_return(true)
      subject
    end

    it "shows targeted delivery funding" do
      expect(summary_list).to have_summary_item("Targeted delivery funding", calculator.total_targeted_delivery_funding)
    end
  end

  context "without total service fees" do
    it { is_expected.not_to have_text "Service fee" }
  end

  context "with total service fees" do
    before do
      allow(calculator).to receive(:total_service_fees).and_return(123)
      subject
    end

    it "shows total service fees" do
      expect(summary_list).to have_summary_item("Service fee", calculator.total_service_fees)
    end
  end

  describe "milestone declarations" do
    let(:declaration_types) { %w[started completed] }

    before do
      started_milestone = create(:milestone, declaration_type: "started")
      completed_milestone = create(:milestone, declaration_type: "completed")
      create(:milestone_statement, milestone: started_milestone, statement:)
      create(:milestone_statement, milestone: completed_milestone, statement:)
      allow(declarations_calculator).to receive(:expected_applications).with("started").and_return(Array.new(10) { :application })
      allow(declarations_calculator).to receive(:expected_applications).with("completed").and_return(Array.new(20) { :application })
      allow(declarations_calculator).to receive(:received_declarations).with("retained-1").and_return(Array.new(30) { :declaration })
      subject
    end

    it "shows a row for every declaration type" do
      expect(rendered).to have_css "tr:nth-child(1) td:nth-child(1)", text: "Started"
      expect(rendered).to have_css "tr:nth-child(2) td:nth-child(1)", text: "Retained-1"
      expect(rendered).to have_css "tr:nth-child(3) td:nth-child(1)", text: "Retained-2"
      expect(rendered).to have_css "tr:nth-child(4) td:nth-child(1)", text: "Completed"
    end

    it "shows expected declaration counts" do
      expect(rendered).to have_css "tr:nth-child(1) td:nth-child(2)", text: "10"
      expect(rendered).to have_css "tr:nth-child(2) td:nth-child(2)", text: "0"
      expect(rendered).to have_css "tr:nth-child(3) td:nth-child(2)", text: "0"
      expect(rendered).to have_css "tr:nth-child(4) td:nth-child(2)", text: "20"
    end

    it "shows received declaration counts" do
      expect(rendered).to have_css "tr:nth-child(1) td:nth-child(3)", text: "0"
      expect(rendered).to have_css "tr:nth-child(2) td:nth-child(3)", text: "30"
      expect(rendered).to have_css "tr:nth-child(3) td:nth-child(3)", text: "0"
      expect(rendered).to have_css "tr:nth-child(4) td:nth-child(3)", text: "0"
    end
  end
end
