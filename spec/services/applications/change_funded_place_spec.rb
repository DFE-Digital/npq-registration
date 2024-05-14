# frozen_string_literal: true

require "rails_helper"

RSpec.describe Applications::ChangeFundedPlace do
  let(:params) do
    {
      application:,
    }
  end

  subject(:service) do
    described_class.new(params)
  end

  describe "#change" do
    let(:application) do
      create(:application,
             :accepted,
             eligible_for_funding: true,
             course:,
             lead_provider:,
             cohort:)
    end
    let(:course) { create(:course, :sl) }
    let(:lead_provider) { create(:lead_provider) }
    let(:cohort) { create(:cohort, :current, :with_funding_cap) }

    context "when application funded_place is false" do
      before { params.merge!(funded_place: true) }

      it "sets the funded place to true" do
        application.update!(funded_place: false)
        service.change

        expect(application.reload.funded_place).to be_truthy
      end
    end

    context "when application funded_place is true" do
      before { params.merge!(funded_place: false) }

      it "sets the funded place to false" do
        application.update!(funded_place: true)
        service.change

        expect(application.reload.funded_place).to be_falsey
      end
    end

    describe "validations" do
      before do
        params.merge!(funded_place: true)
      end

      context "when funded_place is present" do
        before { params.merge!(funded_place: true) }

        it "is invalid if the application has not been accepted" do
          application.update!(lead_provider_approval_status: "pending")

          service.change
          expect(service.errors.messages_for(:application)).to include("The application is not accepted (pending)")
        end

        it "is invalid if the application is not eligible for funding" do
          application.update!(eligible_for_funding: false)

          service.change
          expect(service.errors.messages_for(:application)).to include("The application is not eligible for funding (pending)")
        end

        it "is invalid if the cohort does not accept capping and we set a funded place to true" do
          cohort.update!(funding_cap: false)

          service.change
          expect(service.errors.messages_for(:application)).to include("The cohort does not accept funded places (pending)")
        end

        it "is invalid if the cohort does not accept capping and we set a funded place to false" do
          params.merge!(funded_place: false)
          cohort.update!(funding_cap: false)

          service.change
          expect(service.errors.messages_for(:application)).to include("The cohort does not accept funded places (pending)")
        end

        context "when the application is not accepted" do
          let(:application) { create(:application, eligible_for_funding: true) }

          it "does not check for applicable declarations" do
            params.merge!(funded_place: false)

            service.change

            expect(service.errors.messages_for(:application)).to include("The application is not accepted (pending)")
          end
        end
      end

      context "when funded_place is not present" do
        before { params.merge!(funded_place: nil) }

        it "is invalid if funded_place is `nil`" do
          service.change

          expect(service.errors.messages_for(:application)).to include("The entered '#/funded_place' is missing from your request. Check details and try again.")
        end
      end
    end
  end
end
