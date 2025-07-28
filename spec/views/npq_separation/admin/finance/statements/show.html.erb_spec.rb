require "rails_helper"

RSpec.describe "npq_separation/admin/finance/statements/show", type: :view do
  subject { Capybara.string(render) }

  let!(:contract) { create(:contract, course: create(:course, :leading_teaching), statement:) }

  before do
    assign(:statement, statement)
    assign(:special_contracts, [])
    assign(:contracts, [contract])
  end

  context "when the statement is in the current month" do
    let(:statement) { build(:statement, month: Time.zone.today.month, year: Time.zone.today.year) }

    it { is_expected.to have_link("Change", href: npq_separation_admin_finance_change_per_participant_path(contract), visible: :all) }
  end

  context "when the statement is in the past" do
    let(:statement) { build(:statement, month: Time.zone.today.month - 1, year: Time.zone.today.year) }

    it { is_expected.not_to have_link("Change", href: npq_separation_admin_finance_change_per_participant_path(contract), visible: :all) }
  end

  context "when the statement is paid" do
    let(:statement) { build(:statement, :paid, month: Time.zone.today.month, year: Time.zone.today.year) }

    it { is_expected.not_to have_link("Change", href: npq_separation_admin_finance_change_per_participant_path(contract), visible: :all) }
  end
end
