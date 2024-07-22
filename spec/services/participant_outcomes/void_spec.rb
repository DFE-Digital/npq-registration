require "rails_helper"

RSpec.describe ParticipantOutcomes::Void, type: :model do
  let(:course) { create(:course, :senior_leadership) }
  let(:declaration) { create(:declaration, declaration_type, :paid, course:) }
  let(:declaration_type) { :completed }

  subject(:service) { described_class.new(declaration:) }

  describe "#void_outcome" do
    context "when completed declaration" do
      before do
        create(:participant_outcome, :passed, declaration:)
      end

      it "creates new participant outcome record" do
        expect(declaration.participant_outcomes.count).to be(1)

        service.void_outcome

        expect(declaration.participant_outcomes.count).to be(2)
        outcome = declaration.participant_outcomes.latest
        expect(outcome).to be_voided_state
        expect(outcome.completion_date).to eq(declaration.declaration_date)
      end
    end

    context "when outcome is already voided" do
      before do
        create(:participant_outcome, :voided, declaration:)
      end

      it "does not create a new participant outcome record" do
        expect(declaration.participant_outcomes.count).to be(1)

        service.void_outcome

        expect(declaration.participant_outcomes.count).to be(1)
      end
    end

    context "when started declaration" do
      let(:declaration_type) { :started }

      it "does not create participant outcome record" do
        expect(declaration.participant_outcomes.count).to be(0)

        service.void_outcome

        expect(declaration.participant_outcomes.count).to be(0)
      end
    end

    %i[early_headship_coaching_offer additional_support_offer].each do |course_trait|
      context "when the course is #{course_trait}" do
        let(:course) { create(:course, course_trait) }

        it "does not create participant outcome record" do
          expect(declaration.participant_outcomes.count).to be(0)

          service.void_outcome

          expect(declaration.participant_outcomes.count).to be(0)
        end
      end
    end
  end
end
