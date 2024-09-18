require "rails_helper"

RSpec.describe NpqSeparation::ApplicationTallyComponent, type: :component do
  subject { described_class.new(Application.where(cohort:), :course) }

  let(:cohort) { create :cohort, :current }
  let(:courses) { 2.times.map { create :course } }

  before do
    create(:application, cohort:, course: courses[0])
    create(:application, cohort:, course: courses[0])
    create(:application, cohort:, course: courses[1])
  end

  it "returns the correct rows" do
    expect(subject.rows).to eq([
      [courses[0].name, 2],
      [courses[1].name, 1],
    ])
  end
end
