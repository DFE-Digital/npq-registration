# frozen_string_literal: true

require "rails_helper"

RSpec.describe NpqSeparation::Admin::StatementDetailsComponent, type: :component do
  include Rails.application.routes.url_helpers

  subject(:rendered) { render_inline described_class.new(statement:) }

  let(:statement) { create(:statement) }

  let(:calculator) do
    OpenStruct.new(
      show_targeted_delivery_funding?: false,
      total_targeted_delivery_funding: 99,
      total_service_fees: 0,
      total_output_payment: 100.12,
      total_clawbacks: 50.34,
      total_payment: 49.78,
      total_starts: 1,
      total_retained: 2,
      total_completed: 3,
      total_voided: 4,
    )
  end

  before do
    allow(::Statements::SummaryCalculator).to receive(:new).and_return(calculator)
  end

  it { is_expected.to have_text t(".totals") }
  it { is_expected.to have_text(/#{t('.output_payment')}\s+£#{calculator.total_output_payment}/) }
  it { is_expected.to have_text(/#{t('.clawbacks')}\s+-£#{calculator.total_clawbacks}/) }
  it { is_expected.to have_text(/#{t('.total_net_vat')}\s+£#{calculator.total_payment}/) }
  it { is_expected.to have_text(/#{t('.cut_off_date')}\s+#{statement.deadline_date.to_fs(:govuk)}/) }
  it { is_expected.to have_text(/#{t('.total_starts')}\s+#{calculator.total_starts}/) }
  it { is_expected.to have_text(/#{t('.total_retained')}\s+#{calculator.total_retained}/) }
  it { is_expected.to have_text(/#{t('.total_completed')}\s+#{calculator.total_completed}/) }
  it { is_expected.to have_text(/#{t('.total_voids')}\s+#{calculator.total_voided}/) }
  it { is_expected.to have_link t(".view", href: npq_separation_admin_finance_voided_index_path(statement)) }

  context "without targeted delivery funding" do
    it { is_expected.not_to have_text t(".targeted_delivery_funding") }
  end

  context "with targeted delivery funding" do
    before do
      allow(calculator).to receive(:show_targeted_delivery_funding?).and_return(true)
    end

    it { is_expected.to have_text(/#{t('.targeted_delivery_funding')}\s+£#{calculator.total_targeted_delivery_funding}/) }
  end

  context "without total service fees" do
    it { is_expected.not_to have_text t(".service_fee") }
  end

  context "with total service fees" do
    before do
      allow(calculator).to receive(:total_service_fees).and_return(123)
    end

    it { is_expected.to have_text(/#{t('.service_fee')}\s+£#{calculator.total_service_fees}/) }
  end
end
