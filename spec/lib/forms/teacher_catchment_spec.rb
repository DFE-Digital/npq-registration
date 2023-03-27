require "rails_helper"

RSpec.describe Forms::TeacherCatchment, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:teacher_catchment) }

    it "must have teacher_catchment_country if teacher_catchment is another" do
      subject.teacher_catchment = "egerklgjknee"
      expect(subject).not_to be_valid

      subject.teacher_catchment = "another"
      expect(subject).not_to be_valid

      subject.teacher_catchment_country = "rgnerjkgnerkjgn"
      expect(subject).not_to be_valid

      subject.teacher_catchment_country = "China"
      expect(subject).to be_valid
    end
  end
end
