require "rails_helper"

RSpec.describe NpqSeparation::Admin::CoursePaymentOverviewComponent, type: :component do
  subject { render_inline described_class.new(statement:, contract:) }

  let(:statement) { create(:statement) }
  let(:course) { create(:course, :leading_literacy) }
  let(:contract) { create(:contract, course:, statement:) }

  before { create :schedule, :npq_specialist_autumn }

  it { is_expected.to have_css "h2", text: contract.course.name }
end
