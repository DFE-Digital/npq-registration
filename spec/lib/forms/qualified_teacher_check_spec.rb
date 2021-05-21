require "rails_helper"

RSpec.describe Forms::QualifiedTeacherCheck, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:trn) }
    it { is_expected.to validate_length_of(:trn).is_at_least(7).is_at_most(10) }
    it { is_expected.to validate_presence_of(:first_name) }
    it { is_expected.to validate_presence_of(:last_name) }
    it { is_expected.to validate_presence_of(:date_of_birth) }
  end
end
