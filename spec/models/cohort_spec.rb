require "rails_helper"

RSpec.describe Cohort, type: :model do
  describe "validations" do
    describe "#start_year" do
      it { is_expected.to validate_presence_of(:start_year) }

      it {
        expect(subject)
          .to(
            validate_numericality_of(:start_year)
              .is_greater_than_or_equal_to(2021)
              .is_less_than(2030),
          )
      }
    end
  end
end
