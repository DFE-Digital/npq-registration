require "rails_helper"

RSpec.describe "update_declaration" do
  describe "void" do
    subject(:run_task) { Rake::Task["update_declaration:void"].invoke(declaration.ecf_id) }

    let(:statement) { create(:statement, :next_output_fee) }

    after { Rake::Task["update_declaration:void"].reenable }

    context "when the declaration is submitted" do
      let(:declaration) { create(:declaration, lead_provider: statement.lead_provider, cohort: statement.cohort) }

      it "voids the declaration" do
        run_task
        expect(declaration.reload.state).to eq "voided"
      end
    end

    context "when the declaration is paid" do
      let(:declaration) { create(:declaration, :paid, lead_provider: statement.lead_provider, cohort: statement.cohort) }

      it "sets the application to awaiting_clawback" do
        run_task
        expect(declaration.reload.state).to eq "awaiting_clawback"
      end
    end
  end
end
