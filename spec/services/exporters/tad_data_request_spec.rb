require "rails_helper"

RSpec.describe Exporters::TadDataRequest do
  let(:file) { Tempfile.new }
  let(:course) { create(:course, :senior_leadership, name: "NPQ Senior Leadership") }
  let(:cohort) { create(:cohort, start_year: 2023) }
  let(:schedule) { create(:schedule, cohort: cohort, course_group: course.course_group, name: "Schedule Autumn 2023") }
  let(:user) { create(:user, full_name: "John Doe", email: "john@example.com") }
  let(:user2) { create(:user) }

  let(:application) do
    create(
      :application,
      :accepted,
      :eligible_for_funding,
      user:,
      course:,
      schedule:,
      cohort:,
    )
  end

  let(:application2) do
    create(
      :application,
      :accepted,
      :eligible_for_funding,
      user: user2,
      course:,
      cohort:,
      schedule:,
    )
  end

  before do
    create(:declaration, :paid, cohort: cohort, application: application)
    application2
  end

  subject do
    described_class.new(cohort: cohort, schedules: [schedule], courses: [course], file: file)
  end

  describe "#applications" do
    it "selects applications" do
      expect(subject.applications.count).to eq(1)

      application = subject.applications.first
      expect(application.user).to eq(user)
    end
  end

  describe "#call" do
    let(:csv) do
      <<~CSV
        Full Name,Email,User ID,Teacher Reference Number,School URN,Lead Provider Name,Course Name,Schedule,Cohort Start Year,Eligible for Funding,Participant Status,Targeted Support Funding Eligibility,Targeted Delivery Funding Eligibility,Outcome 1,Outcome 1 Date,Outcome 2,Outcome 1 Date,Outcome 3,Outcome 3 Date,Outcome 4,Outcome 4 Date
        John Doe,john@example.com,#{user.id},#{user.trn},#{application.school.urn},Ambition Institute,NPQ Senior Leadership,Schedule Autumn 2023,#{cohort.identifier},true,active,false,false
      CSV
    end

    it "saves applications" do
      subject.call

      file.rewind
      expect(file.read).to eq(csv)
    end
  end
end
