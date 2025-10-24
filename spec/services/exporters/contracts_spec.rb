require "rails_helper"

RSpec.describe Exporters::Contracts do
  subject { described_class.new(cohort:).call }

  let(:lead_provider) { create(:lead_provider, name: "Some Lead Provider") }
  let(:lead_provider_2) { create(:lead_provider, name: "Another Provider") }
  let(:course) { create(:course, :early_years_leadership) }
  let(:course_2) { create(:course, :senior_leadership) }

  let(:cohort) { create(:cohort, :current) }
  let(:statement) { create(:statement, cohort:, lead_provider:) }
  let(:statement_2) { create(:statement, cohort:, lead_provider:) }
  let(:statement_3_different_lead_provider) { create(:statement, cohort:, lead_provider: lead_provider_2) }

  let(:other_cohort) { create(:cohort, :previous) }
  let(:statement_other_cohort) { create(:statement, cohort: other_cohort) }

  let(:contract_template) { create(:contract_template) }
  let(:duplicate_contract_template) { create(:contract_template) } # yes, there are duplicate contracts templates in production
  let(:contract_template_2) { create(:contract_template, per_participant: 801, monthly_service_fee: nil) }
  let(:other_cohort_contract_template) { create(:contract_template, per_participant: 802) }

  before do
    create(:contract, statement:, course:, contract_template:)
    create(:contract, statement: statement_2, course:, contract_template: duplicate_contract_template)
    create(:contract, statement: statement_other_cohort, course:, contract_template: other_cohort_contract_template)
    create(:contract, statement:, course: course_2, contract_template: contract_template_2)
    create(:contract, statement: statement_3_different_lead_provider, course:, contract_template:)
  end

  it "generates a CSV with the correct header" do
    expect(subject.lines[0]).to eq "#{Exporters::Contracts::FIELD_NAMES.join(",")}\n"
  end

  it "generates a CSV of contracts" do
    expect(subject.lines.count).to eq(4) # header + contact_template for lead_provider + contract_template for lead_provider_2 + contract_template_2 for lead_provider_2

    expect(subject.lines.drop(1).map(&:chomp)).to contain_exactly(
      [
        "Some Lead Provider",
        course.identifier,
        contract_template.recruitment_target,
        contract_template.per_participant,
        contract_template.service_fee_installments,
        contract_template.special_course,
        contract_template.monthly_service_fee,
      ].join(","),
      [
        "Some Lead Provider",
        course_2.identifier,
        contract_template_2.recruitment_target,
        contract_template_2.per_participant,
        contract_template_2.service_fee_installments,
        contract_template_2.special_course,
        0,
      ].join(","),
      [
        "Another Provider",
        course.identifier,
        contract_template.recruitment_target,
        contract_template.per_participant,
        contract_template.service_fee_installments,
        contract_template.special_course,
        contract_template.monthly_service_fee,
      ].join(","),
    )
  end
end
