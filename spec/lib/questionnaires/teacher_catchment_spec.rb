require "rails_helper"

RSpec.describe Questionnaires::TeacherCatchment, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:teacher_catchment) }
  end
end
