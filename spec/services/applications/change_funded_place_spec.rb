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
    let(:course) { create(:course, :senior_leadership) }
    let(:lead_provider) { create(:lead_provider) }
    let(:cohort) { create(:cohort, :current, :with_funding_cap) }

    it "reloads application after action" do
      params.merge!(funded_place: true)
      application.update!(funded_place: false)

      expect(service.application).to receive(:reload)
      service.change
    end

    context "when the application funded place is false and the funded_place param is true" do
      before do
        params.merge!(funded_place: true)
        application.update!(funded_place: false)
      end

      it "sets the funded place to true" do
        expect { service.change }.to change { application.reload.funded_place }.to(true)
      end
    end

    context "when the application funded place is true and the funded_place param is false" do
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

      context "when funded_place is present in the params" do
        before { params.merge!(funded_place: true) }

        it "is invalid if the application has not been accepted" do
          application.update!(lead_provider_approval_status: "pending")

          service.change

          expect(service).to have_error(:application, :cannot_change_funded_status_from_non_accepted, "You must accept the application before attempting to change the '#/funded_place' setting.")
        end

        it "is invalid if the application is not eligible for funding" do
          application.update!(eligible_for_funding: false, funded_place: false)

          service.change

          expect(service).to have_error(:application, :cannot_change_funded_status_non_eligible, "This participant is not eligible for funding. Contact us if you think this is wrong.")
        end

        context "when the cohort does not accept capping" do
          let(:cohort) { create(:cohort, :current, :without_funding_cap) }

          it "is invalid when we have a true funded_place param" do
            service.change
            expect(service).to have_error(:application, :cohort_does_not_accept_capping, "Leave the '#/funded_place' field blank. It's only needed for participants starting NPQs from autumn 2024 onwards.")
          end

          it "is invalid when we have a false funded_place param" do
            params.merge!(funded_place: false)
            service.change
            expect(service).to have_error(:application, :cohort_does_not_accept_capping, "Leave the '#/funded_place' field blank. It's only needed for participants starting NPQs from autumn 2024 onwards.")
          end
        end

        context "when the application is not accepted" do
          let(:application) { create(:application, eligible_for_funding: true) }

          it "does not allow the funded place to be changed" do
            params.merge!(funded_place: false)

            service.change

            expect(service).to have_error(:application, :cannot_change_funded_status_from_non_accepted, "You must accept the application before attempting to change the '#/funded_place' setting.")
          end
        end

        context "with declarations" do
          shared_examples "not allowing funded place to change" do
            context "when changing from false to true" do
              before do
                application.update!(funded_place: false)
                params.merge!(funded_place: true)
              end

              it "is invalid" do
                service.change

                expect(service).to have_error(:application, :cannot_change_funded_place, "You cannot change the funded place because declarations have been submitted. You will need to void the existing declarations and resubmit them after changing the funded place.")
              end
            end

            context "when changing from true to false" do
              before do
                application.update!(funded_place: true)
                params.merge!(funded_place: false)
              end

              it "is invalid" do
                service.change

                expect(service).to have_error(
                  :application,
                  :cannot_change_funded_place,
                  "You cannot change the funded place because declarations have been submitted." \
                  " You will need to void the existing declarations and resubmit them after changing the funded place.",
                )
              end
            end
          end

          shared_examples "allowing funded place to change" do
            context "when changing from false to true" do
              before do
                application.update!(funded_place: false)
                params.merge!(funded_place: true)
              end

              it "is valid" do
                service.change

                expect(service.errors.messages_for(:application)).to be_empty
              end
            end

            context "when changing from true to false" do
              before do
                application.update!(funded_place: true)
                params.merge!(funded_place: false)
              end

              it "is valid" do
                service.change

                expect(service.errors.messages_for(:application)).to be_empty
              end
            end
          end

          context "when there are billable or changeable declarations" do
            (Declaration::BILLABLE_STATES | Declaration::CHANGEABLE_STATES).each do |state|
              it_behaves_like "not allowing funded place to change" do
                before { create(:declaration, application:, state:) }
              end
            end
          end

          context "when there are no billable or changeable declarations" do
            (Declaration.states.values - (Declaration::BILLABLE_STATES | Declaration::CHANGEABLE_STATES)).each do |state|
              it_behaves_like "allowing funded place to change" do
                before { create(:declaration, application:, state:) }
              end
            end
          end
        end

        context "when the funded_place param is a string" do
          context "when the funded_place param is `true`" do
            before { params.merge!(funded_place: "true") }

            it "returns funded_place is required error" do
              service.change

              expect(service).to have_error(:funded_place, :inclusion, "Set '#/funded_place' to true or false.")
            end
          end

          context "when the funded_place param is `false`" do
            before { params.merge!(funded_place: "false") }

            it "returns funded_place is required error" do
              service.change
              expect(service).to have_error(:funded_place, :inclusion, "Set '#/funded_place' to true or false.")
            end
          end

          context "when the funded_place param is `null`" do
            before { params.merge!(funded_place: "null") }

            it "returns funded_place is required error" do
              service.change
              expect(service).to have_error(:funded_place, :inclusion, "Set '#/funded_place' to true or false.")
            end
          end

          context "when the funded_place param is an empty string" do
            before { params.merge!(funded_place: "") }

            it "returns funded_place is required error" do
              service.change
              expect(service).to have_error(:funded_place, :inclusion, "Set '#/funded_place' to true or false.")
            end
          end
        end
      end

      context "when the funded_place param is not present in the params" do
        before { params.merge!(funded_place: nil) }

        it "returns funded_place is required error" do
          service.change
          expect(service).to have_error(:funded_place, :inclusion, "Set '#/funded_place' to true or false.")
        end
      end
    end
  end
end
