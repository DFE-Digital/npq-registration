require "rails_helper"

RSpec.describe Forms::TeacherReferenceNumber, type: :model do
  describe "validations" do
    it { is_expected.to validate_inclusion_of(:trn_knowledge).in_array(Forms::TeacherReferenceNumber::VALID_TRN_KNOWLEDGE_OPTIONS) }
  end
end
