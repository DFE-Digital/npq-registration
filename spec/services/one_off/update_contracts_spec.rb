require "rails_helper"

RSpec.describe OneOff::UpdateContracts do
  describe ".call" do
    let(:year) { 2024 }
    let(:month) { 12 }
    let(:cohort_year) { 2024 }
    let(:csv_file) { Tempfile.new }
    let(:csv_path) { csv_file.path }
    let(:csv_content) do
      <<~CSV
        provider_name,course_identifier,per_participant
        Provider 1,#{Course::NPQ_SENCO},1000
        Provider 2,#{Course::NPQ_HEADSHIP},2000
      CSV
    end

    let(:lead_provider_1) { create(:lead_provider, name: "Provider 1") }
    let(:lead_provider_2) { create(:lead_provider, name: "Provider 2") }
    let(:cohort) { create(:cohort, start_year: cohort_year) }
    let(:course_1) { create(:course, :senco) }
    let(:course_2) { create(:course, :headship) }
    let(:statement_1) { create(:statement, year: year, month: month, cohort: cohort, lead_provider: lead_provider_1) }
    let(:statement_2) { create(:statement, year: year, month: month, cohort: cohort, lead_provider: lead_provider_2) }
    let(:contract_template_1) { create(:contract_template, per_participant: 100) }
    let(:contract_template_2) { create(:contract_template, per_participant: 200) }
    let!(:contract_1) { create(:contract, contract_template: contract_template_1, statement: statement_1, course: course_1) }
    let!(:contract_2) { create(:contract, contract_template: contract_template_2, statement: statement_2, course: course_2) }

    before do
      csv_file.write(csv_content)
      csv_file.rewind
    end

    context "when operation is successful" do
      it "changes the contract templates" do
        OneOff::UpdateContracts.call(year: 2024, month: 12, cohort_year: 2024, csv_path:)

        expect(contract_1.reload.contract_template).not_to eq(contract_template_1)
        expect(contract_2.reload.contract_template).not_to eq(contract_template_2)

        expect(contract_1.reload.contract_template.per_participant).to eq(1000.0)
        expect(contract_2.reload.contract_template.per_participant).to eq(2000.0)
      end

      describe "logs" do
        let(:csv_content) do
          <<~CSV
            provider_name,course_identifier,per_participant
            Provider 1,#{Course::NPQ_SENCO},1000
          CSV
        end

        let(:expected_message) do
          from_id = contract_template_1.id
          to_id = contract_1.reload.contract_template.id

          "[UpdateContract] Contract #{contract_1.id} got template updated: #{from_id} to #{to_id}"
        end

        it "has proper output" do
          allow(Rails.logger).to receive(:info)

          OneOff::UpdateContracts.call(year: 2024, month: 12, cohort_year: 2024, csv_path:)

          expect(Rails.logger)
            .to have_received(:info).with(expected_message)
        end
      end
    end

    context "when record is missing from the file" do
      let(:csv_content) do
        <<~CSV
          provider_name,course_identifier,per_participant
          Provider 1,#{Course::NPQ_SENCO},1000
          Provider 2,#{Course::NPQ_HEADSHIP},2000
          Provider 3,#{Course::NPQ_HEADSHIP},2000
        CSV
      end

      it "makes the whole process unsuccessful" do
        expect(contract_1.reload.contract_template.per_participant).not_to eq(1000.0)
        expect(contract_2.reload.contract_template.per_participant).not_to eq(2000.0)
      end

      it "raises the exception" do
        expect {
          OneOff::UpdateContracts.call(year: 2024, month: 12, cohort_year: 2024, csv_path:)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
