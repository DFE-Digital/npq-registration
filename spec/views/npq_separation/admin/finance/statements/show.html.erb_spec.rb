require "rails_helper"

RSpec.describe "npq_separation/admin/finance/statements/show", type: :view do
  subject { Capybara.string(render) }

  let(:contract) { create(:contract, course:, statement:) }
  let(:course) { create(:course, :leading_teaching) }

  before do
    assign(:statement, statement)
    assign(:special_contracts, [])
    assign(:contracts, [contract])
    without_partial_double_verification { allow(view).to receive(:current_admin).and_return(admin_user) }
  end

  context "when the user is a super admin" do
    let(:admin_user) { create(:admin, super_admin: true) }

    context "when the statement is in the current month" do
      let(:statement) { build(:statement, for_date: Time.zone.today) }

      it { is_expected.to have_link("Change", href: npq_separation_admin_finance_change_per_participant_path(contract), visible: :all) }
    end

    context "when the statement is in the past" do
      let(:statement) { build(:statement, for_date: 1.month.ago) }

      it { is_expected.not_to have_link("Change", href: npq_separation_admin_finance_change_per_participant_path(contract), visible: :all) }
    end

    context "when the statement is paid" do
      let(:statement) { build(:statement, for_date: Time.zone.today) }

      before { statement.update!(state: "paid") }

      it { is_expected.not_to have_link("Change", href: npq_separation_admin_finance_change_per_participant_path(contract), visible: :all) }
    end
  end

  context "when the user is not a super admin" do
    let(:admin_user) { create(:admin) }

    let(:statement) { build(:statement, for_date: Time.zone.today) }

    it { is_expected.not_to have_link("Change", href: npq_separation_admin_finance_change_per_participant_path(contract), visible: :all) }
  end
end
