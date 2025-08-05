# frozen_string_literal: true

require "rails_helper"

RSpec.describe Applications::ChangeTrainingStatus, type: :model do
  subject(:service) { described_class.new(application:, training_status:, reason:) }

  let(:application) { create(:application, :accepted) }
  let(:training_status) { nil }
  let(:reason) { nil }

  describe "validation" do
    it { is_expected.to validate_presence_of :application }
    it { is_expected.to validate_inclusion_of(:training_status).in_array(%w[active deferred withdrawn]) }

    describe "#training_status" do
      context "when application is pending" do
        let(:application) { create(:application, :pending) }

        it { is_expected.not_to be_valid }
      end
    end

    describe "#reason" do
      context "with training_status set to blank" do
        let(:training_status) { nil }

        it { is_expected.to allow_values("").for(:reason) }
      end

      context "with training_status set to active" do
        let(:training_status) { "active" }

        it { is_expected.to allow_values("").for(:reason) }
      end

      context "with training_status set to deferred" do
        let(:training_status) { "deferred" }

        it { is_expected.to validate_inclusion_of(:reason).in_array(Participants::Defer::DEFERRAL_REASONS) }
      end

      context "with training_status set to withdrawn" do
        let(:training_status) { "withdrawn" }

        it { is_expected.to validate_inclusion_of(:reason).in_array(Participants::Withdraw::WITHDRAWAL_REASONS) }
      end
    end

    describe "checking for declarations" do
      subject { service.tap(&:valid?).errors[:training_status] }

      let(:training_status) { "deferred" }

      context "with declarations" do
        before { create(:declaration, application:) }

        it { is_expected.not_to include(/cannot defer/i) }
      end

      context "without declarations" do
        it { is_expected.to include(/cannot defer/i) }
      end

      context "with withdrawn training_status" do
        let(:training_status) { "withdrawn" }

        it { is_expected.not_to include(/cannot defer/i) }
      end

      context "with active training_status" do
        let(:training_status) { "active" }

        it { is_expected.not_to include(/cannot defer/i) }
      end

      context "without pending lead_provider_approval_status on application" do
        let(:application) { create(:application, :pending) }

        it { is_expected.not_to include(/cannot defer/i) }
      end
    end
  end

  describe "#training_status_options" do
    subject { service.training_status_options }

    context "when application set to active" do
      let(:application) { create(:application, :accepted, training_status: "active") }

      it { is_expected.to match_array %w[deferred withdrawn] }
    end

    context "when application set to deferred" do
      let(:application) { create(:application, :accepted, training_status: "deferred") }

      it { is_expected.to match_array %w[active withdrawn] }
    end

    context "when application set to withdrawn" do
      let(:application) { create(:application, :accepted, training_status: "withdrawn") }

      it { is_expected.to match_array %w[active deferred] }
    end
  end

  describe "#reason_options" do
    it "groups by training status" do
      expect(service.reason_options.keys).to match_array(%w[deferred withdrawn])
    end

    it "has reasons for deferral" do
      expect(service.reason_options["deferred"])
        .to match_array(Participants::Defer::DEFERRAL_REASONS)
    end

    it "has reasons for withdrawn" do
      expect(service.reason_options["withdrawn"])
        .to match_array(Participants::Withdraw::WITHDRAWAL_REASONS)
    end
  end

  describe "#change_training_status" do
    subject(:change_training_status) { service.change_training_status }

    context "when withdrawing" do
      before do
        allow(Participants::Withdraw).to receive(:new).and_call_original
        create(:declaration, application:)
      end

      let(:training_status) { "withdrawn" }
      let(:reason) { Participants::Withdraw::WITHDRAWAL_REASONS.first }

      it { is_expected.to be true }

      it "updates the applications training status" do
        expect { change_training_status }
          .to change { application.reload.training_status }.from("active").to("withdrawn")
      end

      it "adds an application state" do
        expect { change_training_status }
          .to change { application.application_states.where(state: :withdrawn).count }
                .from(0)
                .to(1)
      end

      it "stores the reason" do
        change_training_status

        expect(application.reload.application_states.order(id: :desc).first.reason)
          .to eq(reason)
      end
    end

    context "when deferring" do
      before do
        allow(Participants::Defer).to receive(:new).and_call_original
        create(:declaration, application:)
      end

      let(:training_status) { "deferred" }
      let(:reason) { Participants::Defer::DEFERRAL_REASONS.first }

      it { is_expected.to be true }

      it "updates the applications training status" do
        expect { change_training_status }
          .to change { application.reload.training_status }.from("active").to("deferred")
      end

      it "adds an application state" do
        expect { change_training_status }
          .to change { application.application_states.where(state: :deferred).count }
                .from(0)
                .to(1)
      end

      it "stores the reason" do
        change_training_status

        expect(application.reload.application_states.order(id: :desc).first.reason)
          .to eq(reason)
      end
    end

    context "when resuming" do
      before { allow(Participants::Resume).to receive(:new).and_call_original }

      let :application do
        create(:application, :deferred).tap do |application|
          create(:declaration, application:)
        end
      end

      let(:training_status) { "active" }
      let(:reason) { "something random" }

      it { is_expected.to be true }

      it "updates the applications training status" do
        expect { change_training_status }
          .to change { application.reload.training_status }.from("deferred").to("active")
      end

      it "adds an application state" do
        expect { change_training_status }
          .to change { application.application_states.where(state: :active).count }
                .from(0)
                .to(1)
      end

      it "does not store the reason" do
        change_training_status

        expect(application.reload.application_states.order(id: :desc).first.reason)
          .to be_nil
      end
    end

    context "with invalid update" do
      it { is_expected.to be false }

      it "does not change the applications training status" do
        expect { change_training_status }
          .to(not_change { application.reload.training_status })
      end

      it "adds an application state" do
        expect { change_training_status }
          .to(not_change { application.application_states.where(state: :withdrawn).count })
      end
    end

    context "with unchanged training_status" do
      let(:training_status) { "active" }

      it { is_expected.to be true }

      it "does not change the applications training status" do
        expect { change_training_status }
          .to(not_change { application.reload.training_status })
      end

      it "adds an application state" do
        expect { change_training_status }
          .to(not_change { application.application_states.where(state: :withdrawn).count })
      end
    end
  end
end
