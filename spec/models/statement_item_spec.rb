require "rails_helper"

RSpec.describe StatementItem, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:statement_id) }
    it { is_expected.to validate_presence_of(:declaration_id) }
    it { is_expected.to validate_inclusion_of(:state).in_array(StatementItem::STATES) }
  end
end
