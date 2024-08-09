require "rails_helper"

RSpec.describe API::DeclarationSerializer, type: :serializer do
  let(:declaration) { create(:declaration) }

  describe "core attributes" do
    subject(:response) { JSON.parse(described_class.render(declaration)) }

    it "serializes the `id`" do
      declaration.ecf_id = "fe1a5280-1b13-4b09-b9c7-e2b01d37e851"

      expect(response["id"]).to eq("fe1a5280-1b13-4b09-b9c7-e2b01d37e851")
    end

    it "serializes the `type`" do
      response = JSON.parse(described_class.render(declaration))

      expect(response["type"]).to eq("participant-declaration")
    end
  end

  describe "nested attributes" do
    %i[v1 v2 v3].each do |view|
      context "when serializing the `#{view}` view" do
        subject(:attributes) { JSON.parse(described_class.render(declaration, view:))["attributes"] }

        it "serializes the `participant_id`" do
          expect(attributes["participant_id"]).to eq(declaration.application.user.ecf_id)
        end

        it "serializes the `declaration_type`" do
          expect(attributes["declaration_type"]).to eq(declaration.declaration_type)
        end

        it "serializes the `course_identifier`" do
          expect(attributes["course_identifier"]).to eq(declaration.application.course.identifier)
        end

        it "serializes the `declaration_date`" do
          expect(attributes["declaration_date"]).to eq(declaration.declaration_date.rfc3339)
        end

        it "serializes the `updated_at`" do
          expect(attributes["updated_at"]).to eq(declaration.updated_at.rfc3339)
        end

        context "when participant_outcome is the latest" do
          let(:old_datetime) { Time.utc(2023, 5, 5, 5, 0, 0) }
          let(:latest_datetime) { Time.utc(2024, 8, 8, 8, 0, 0) }

          before do
            travel_to(old_datetime) do
              declaration
              create(:participant_outcome, declaration:)
              create(:statement_item, declaration:)
            end
            declaration.participant_outcomes.first.update!(updated_at: latest_datetime)
          end

          it "returns participant_outcome's `updated_at`" do
            declaration.reload
            expect(attributes["updated_at"]).to eq(latest_datetime.rfc3339)
          end
        end

        context "when statement_item is the latest" do
          let(:old_datetime) { Time.utc(2023, 5, 5, 5, 0, 0) }
          let(:latest_datetime) { Time.utc(2024, 8, 8, 8, 0, 0) }

          before do
            travel_to(old_datetime) do
              declaration
              create(:participant_outcome, declaration:)
              create(:statement_item, declaration:)
            end
            declaration.statement_items.first.update!(updated_at: latest_datetime)
          end

          it "returns statement_item's `updated_at`" do
            declaration.reload
            expect(attributes["updated_at"]).to eq(latest_datetime.rfc3339)
          end
        end

        it "serializes the `state`" do
          expect(attributes["state"]).to eq(declaration.state)
        end

        context "when there is no participant outcome" do
          it "serializes `has_passed`" do
            expect(attributes["has_passed"]).to be_nil
          end
        end

        context "when there are participant outcomes" do
          let!(:voided_outcome) { create(:participant_outcome, :voided, declaration:) }
          let!(:passed_outcome) { create(:participant_outcome, :passed, declaration:) }
          let!(:failed_outcome) { create(:participant_outcome, :failed, declaration:) }

          context "when the latest outcome is voided" do
            before { voided_outcome.update!(created_at: 1.day.from_now) }

            it "serializes `has_passed`" do
              expect(attributes["has_passed"]).to be_nil
            end
          end

          context "when the latest outcome has passed" do
            before { passed_outcome.update!(created_at: 1.day.from_now) }

            it "serializes `has_passed`" do
              expect(attributes["has_passed"]).to be(true)
            end
          end

          context "when the latest outcome has failed" do
            before { failed_outcome.update!(created_at: 1.day.from_now) }

            it "serializes `has_passed`" do
              expect(attributes["has_passed"]).to be(false)
            end
          end
        end
      end
    end

    context "when serializing the `v1` view" do
      subject(:attributes) { JSON.parse(described_class.render(declaration, view: :v1))["attributes"] }

      it "serializes `voided`" do
        expect(attributes["voided"]).to eq(declaration.voided_state?)
      end

      it "serializes `eligible_for_payment`" do
        expect(attributes["eligible_for_payment"]).to eq(declaration.eligible_for_payment?)
      end
    end

    context "when serializing the `v3` view" do
      subject(:attributes) { JSON.parse(described_class.render(declaration, view: :v3))["attributes"] }

      it "serializes the `created_at`" do
        expect(attributes["created_at"]).to eq(declaration.created_at.rfc3339)
      end

      it "serializes the `uplift_paid`" do
        expect(attributes["uplift_paid"]).to eq(declaration.uplift_paid?)
      end

      it "serializes the `ineligible_for_funding_reason`" do
        expect(attributes["ineligible_for_funding_reason"]).to eq(declaration.ineligible_for_funding_reason)
      end

      context "when there is no billable statement item" do
        it "serializes the `statement_id`" do
          expect(attributes["statement_id"]).to be_nil
        end
      end

      context "when there is a billable statement item" do
        let(:billable_statement_item) { create(:statement_item, :payable) }
        let(:declaration) { billable_statement_item.declaration }

        it "serializes the `statement_id`" do
          expect(attributes["statement_id"]).to eq(billable_statement_item.statement.ecf_id)
        end
      end

      context "when there is no refundable statement item" do
        it "serializes the `clawback_statement_id`" do
          expect(attributes["clawback_statement_id"]).to be_nil
        end
      end

      context "when there is a refundable statement item" do
        let(:refundable_statement_item) { create(:statement_item, :clawed_back) }
        let(:declaration) { refundable_statement_item.declaration }

        it "serializes the `clawback_statement_id`" do
          expect(attributes["clawback_statement_id"]).to eq(refundable_statement_item.statement.ecf_id)
        end
      end

      it "serializes the `lead_provider_name`" do
        expect(attributes["lead_provider_name"]).to eq(declaration.lead_provider.name)
      end
    end
  end
end
