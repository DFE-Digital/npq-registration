require "rails_helper"

RSpec.describe NpqSeparation::ApplicationTallyComponent, type: :component do
  subject { described_class.new(Application.where(cohort:), :course) }

  let(:cohort) { create :cohort, :current }
  let(:course_1) { create :course, :early_headship_coaching_offer }
  let(:course_2) { create :course, :additional_support_offer }

  before do
    create(:application, cohort:, course: course_1)
    create(:application, cohort:, course: course_1)
    create(:application, cohort:, course: course_2)
  end

  it "returns the correct rows" do
    expect(subject.rows).to eq([
      [course_2.name, 1],
      [course_1.name, 2],
    ])
  end
end