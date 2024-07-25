# frozen_string_literal: true

require "rails_helper"

RSpec.describe Applications::ChangeFundedPlace, type: :model do
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
      before do
        params.merge!(funded_place: true)
        application.update!(funded_place: false)
      end

      it "sets the funded place to true" do
        expect { service.change }.to change { application.reload.funded_place }.to(true)
      end
    end

    context "when application funded_place is true" do
      before do
        params.merge!(funded_place: false)
        application.update!(funded_place: true)
      end

      it "sets the funded place to false" do
        expect { service.change }.to change { application.reload.funded_place }.to(false)
      end
    end

    describe "validations" do
      it { is_expected.to validate_presence_of(:application).with_message("The entered '#/application' is missing from your request. Check details and try again.") }

      context "when funded_place is present" do
        before { params.merge!(funded_place: true) }

        it "is invalid if the application has not been accepted" do
          application.update!(lead_provider_approval_status: "pending")

          service.change

          expect(service).to have_error(:application, :cannot_change_funded_status_from_non_accepted, "You must accept the application before attempting to change the '#/funded_place' setting.")
        end

        it "is invalid if the application is not eligible for funding" do
          application.update!(eligible_for_funding: false)

          service.change

          expect(service).to have_error(:application, :cannot_change_funded_status_non_eligible, "This participant is not eligible for funding. Contact us if you think this is wrong.")
        end

        it "is invalid if the cohort does not accept capping and we set a funded place to true" do
          cohort.update!(funding_cap: false)

          service.change

          expect(service).to have_error(:application, :cohort_does_not_accept_capping, "Leave the '#/funded_place' field blank. It's only needed for participants starting NPQs from autumn 2024 onwards.")
        end

        it "is invalid if the cohort does not accept capping and we set a funded place to false" do
          params.merge!(funded_place: false)
          cohort.update!(funding_cap: false)

          service.change

          expect(service).to have_error(:application, :cohort_does_not_accept_capping, "Leave the '#/funded_place' field blank. It's only needed for participants starting NPQs from autumn 2024 onwards.")
        end

        context "when the application is not accepted" do
          let(:application) { create(:application, eligible_for_funding: true) }

          it "does not check for applicable declarations" do
            params.merge!(funded_place: false)

            service.change

            expect(service).to have_error(:application, :cannot_change_funded_status_from_non_accepted, "You must accept the application before attempting to change the '#/funded_place' setting.")
          end
        end

        context "with declarations" do
          context "when funded_place is true" do
            before do
              params.merge!(funded_place: true)
            end

            Declaration.states.each_key do |state|
              it "is valid if the application has #{state} declarations" do
                create(:declaration, application:, state:)
                service.change

                expect(service.errors.messages_for(:application)).to be_empty
              end
            end
          end

          context "when funded_place is false" do
            before do
              params.merge!(funded_place: false)
            end

            applicable = %w[submitted eligible payable paid]
            applicable.each do |applicable_state|
              it "is invalid if the application has #{applicable_state} declarations" do
                create(:declaration, application:, state: applicable_state)

                service.change

                expect(service).to have_error(:application, :cannot_change_funded_place, "You must void or claw back your declarations for this participant before being able to set '#/funded_place' to false")
              end
            end

            (Declaration.states.keys - applicable).each do |non_applicable_state|
              it "is valid if the application has #{non_applicable_state} declarations" do
                create(:declaration, application:, state: non_applicable_state)

                service.change

                expect(service.errors.messages_for(:application)).to be_empty
              end
            end
          end
        end

        context "when funded_place is a string" do
          context "when funded_place is `true`" do
            before { params.merge!(funded_place: "true") }

            it "returns funding_place is required error" do
              service.change

              expect(service).to have_error(:funded_place, :inclusion, "Set '#/funded_place' to true or false.")
            end
          end

          context "when funded_place is `false`" do
            before { params.merge!(funded_place: "false") }

            it "returns funding_place is required error" do
              service.change
              expect(service).to have_error(:funded_place, :inclusion, "Set '#/funded_place' to true or false.")
            end
          end

          context "when funded_place is `null`" do
            before { params.merge!(funded_place: "null") }

            it "returns funding_place is required error" do
              service.change
              expect(service).to have_error(:funded_place, :inclusion, "Set '#/funded_place' to true or false.")
            end
          end

          context "when funded_place is an empty string" do
            before { params.merge!(funded_place: "") }

            it "returns funding_place is required error" do
              service.change
              expect(service).to have_error(:funded_place, :inclusion, "Set '#/funded_place' to true or false.")
            end
          end
        end
      end

      context "when funded_place is not present" do
        before { params.merge!(funded_place: nil) }

        it "is invalid if funded_place is `nil`" do
          service.change
          expect(service).to have_error(:funded_place, :inclusion, "Set '#/funded_place' to true or false.")
        end
      end
    end
  end
end
