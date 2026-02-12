require "rails_helper"

RSpec.describe Crons::OutputStatementNotificationsJob, type: :job do
  describe "#perform" do
    let(:date) { Time.zone.local(2026, 1, 1) }
    let(:send_notifications_service) { instance_double(Statements::SendOutputStatementNotifications, call: true) }

    before do
      allow(Statements::SendOutputStatementNotifications).to receive(:new).and_return(send_notifications_service)
      travel_to date
    end

    context "when there are statements with output fee and deadline date in the current month" do
      before { create(:statement, output_fee: true, deadline_date: date.end_of_month) }

      it "calls Statements::SendOutputStatementNotifications to send output statement notifications" do
        described_class.perform_now

        expect(send_notifications_service).to have_received(:call).once
      end
    end

    context "when there are statements with output fee and deadline date in the next month" do
      before { create(:statement, output_fee: true, deadline_date: date.end_of_month + 1.month) }

      it "calls Statements::SendOutputStatementNotifications to send output statement notifications" do
        described_class.perform_now

        expect(send_notifications_service).to have_received(:call).once
      end
    end

    context "when there are no statements with output fee and deadline date in the current or next months" do
      before { create(:statement, output_fee: true, deadline_date: date.end_of_month + 2.months) }

      it "does not call Statements::SendOutputStatementNotifications to send output statement notifications" do
        described_class.perform_now

        expect(send_notifications_service).not_to have_received(:call)
      end
    end
  end
end
