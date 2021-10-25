require "rails_helper"

RSpec.describe Forms::TeacherCatchment, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:teacher_catchment) }

    it "must have teacher_catchment_country if teacher_catchment is another" do
      subject.teacher_catchment = "egerklgjknee"
      expect(subject.valid?).to be_falsey

      subject.teacher_catchment = "another"
      expect(subject.valid?).to be_falsey

      subject.teacher_catchment_country = "rgnerjkgnerkjgn"
      expect(subject.valid?).to be_falsey

      subject.teacher_catchment_country = "China"
      expect(subject.valid?).to be_truthy
    end
  end
end
