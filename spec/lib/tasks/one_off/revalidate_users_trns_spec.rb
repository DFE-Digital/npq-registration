require "rails_helper"

RSpec.describe "one_off:revalidate_users_trns" do
  subject :run_task do
    Rake::Task["one_off:revalidate_users_trns"].invoke(dry_run)
  end

  let(:user) { create(:user, trn_verified: false, trn: old_trn, national_insurance_number: "QQ123456B") }
  let(:old_trn) { "1234567" }
  let(:new_trn) { "2345678" }
  let(:cohort) { create(:cohort, start_year: 2025, identifier: "2025b", suffix: "b") }

  before do
    create(:application, :accepted, user:, cohort:)
  end

  after { Rake::Task["one_off:revalidate_users_trns"].reenable }

  context "when dry run false" do
    let(:dry_run) { "false" }

    context "when the user's TRN is successfully revalidated" do
      before do
        allow_any_instance_of(ParticipantValidator).to receive(:call).and_return(
          OpenStruct.new(
            trn: new_trn,
            active_alert: true,
          ),
        )
      end

      it "updates the user to be TRN verified" do
        run_task
        expect(user.reload).to have_attributes(
          trn: new_trn,
          trn_verified: true,
          trn_auto_verified: true,
          active_alert: true,
        )
      end

      it "blanks the user's national insurance number" do
        run_task
        expect(user.reload.national_insurance_number).to be_nil
      end
    end

    context "when the user's TRN is not valid" do
      before do
        allow_any_instance_of(ParticipantValidator).to receive(:call).and_return(nil)
      end

      it "does not update the user" do
        run_task
        expect(user.reload).to have_attributes(
          trn: old_trn,
          trn_verified: false,
          trn_auto_verified: false,
          active_alert: false,
        )
      end
    end
  end

  context "when dry run true" do
    let(:dry_run) { "true" }

    before do
      allow_any_instance_of(ParticipantValidator).to receive(:call).and_return(
        OpenStruct.new(
          trn: new_trn,
          active_alert: true,
        ),
      )
    end

    it "does not update the user" do
      run_task
      expect(user.reload).to have_attributes(
        trn: old_trn,
        trn_verified: false,
        trn_auto_verified: false,
        active_alert: false,
      )
    end
  end
end
