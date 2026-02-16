# frozen_string_literal: true

require "rails_helper"

RSpec.describe Statements::SendOutputStatementNotifications do
  subject { described_class.new.call }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(UpcomingOutputStatementsMailer).to receive(:email_upcoming_output_statements_mail) { mailer_double }
  end

  let(:mailer_double) { instance_double(ActionMailer::MessageDelivery, deliver_now: true) }
  let(:today) { Time.zone.today }
  let(:cohort_2024) { create(:cohort, start_year: 2024) }
  let(:cohort_2025) { create(:cohort, start_year: 2025) }

  let(:statement_deadline_this_month_march_2024_cohort) do
    create(:statement,
           output_fee: true, cohort: cohort_2024, month: 3, year: 2026, deadline_date: today.beginning_of_month, lead_provider: LeadProvider.first)
  end

  let(:statement_deadline_this_month_march_2024_cohort_different_provider) do
    create(:statement,
           output_fee: true, cohort: cohort_2024, month: 3, year: 2026, deadline_date: today.beginning_of_month, lead_provider: LeadProvider.last)
  end

  let(:statement_deadline_this_month_april_2024_cohort) do
    create(:statement,
           output_fee: true, cohort: cohort_2024, month: 4, year: 2026, deadline_date: today.beginning_of_month)
  end

  let(:statement_deadline_this_month_march_2025_cohort) do
    create(:statement,
           output_fee: true, cohort: cohort_2025, month: 3, year: 2026, deadline_date: today.beginning_of_month)
  end

  let(:statement_deadline_this_month_april_2025_cohort) do
    create(:statement,
           output_fee: true, cohort: cohort_2025, month: 4, year: 2026, deadline_date: today.beginning_of_month)
  end

  let(:statement_deadline_later_this_month) do
    create(:statement,
           output_fee: true, cohort: cohort_2024, month: 3, year: 2026, deadline_date: today.end_of_month)
  end

  let(:statement_deadline_next_month) do
    create(:statement,
           output_fee: true, cohort: cohort_2024, month: 3, year: 2026, deadline_date: today.end_of_month + 1.month)
  end

  let(:contracts_team_email_address) { "contracts-team@example.com" }

  context "when a contracts team email is configured" do
    before { allow(ENV).to receive(:[]).with("CONTRACTS_TEAM_EMAIL_ADDRESS").and_return(contracts_team_email_address) }

    context "when there are statements with output fee and deadline date in the current and next months" do
      before do
        statement_deadline_this_month_march_2024_cohort
        statement_deadline_this_month_march_2024_cohort_different_provider
        statement_deadline_this_month_april_2024_cohort
        statement_deadline_this_month_march_2025_cohort
        statement_deadline_this_month_april_2025_cohort
        statement_deadline_later_this_month
        statement_deadline_next_month
      end

      it "sends an email with this and next month's statements" do
        expect(UpcomingOutputStatementsMailer).to receive(:email_upcoming_output_statements_mail).with(
          to: contracts_team_email_address,
          this_months_statements: "* deadline date: #{today.beginning_of_month.to_fs(:govuk)}, cohort: #{cohort_2024.identifier}, statement: March 2026\n" \
          "* deadline date: #{today.beginning_of_month.to_fs(:govuk)}, cohort: #{cohort_2024.identifier}, statement: April 2026\n" \
          "* deadline date: #{today.beginning_of_month.to_fs(:govuk)}, cohort: #{cohort_2025.identifier}, statement: March 2026\n" \
          "* deadline date: #{today.beginning_of_month.to_fs(:govuk)}, cohort: #{cohort_2025.identifier}, statement: April 2026\n" \
          "* deadline date: #{today.end_of_month.to_fs(:govuk)}, cohort: #{cohort_2024.identifier}, statement: March 2026",
          next_months_statements: "* deadline date: #{statement_deadline_next_month.deadline_date.to_fs(:govuk)}, cohort: #{cohort_2024.identifier}, statement: March 2026",
        )
        expect(mailer_double).to receive(:deliver_now)

        subject
      end
    end

    context "when there are no output satements for the current month" do
      before { statement_deadline_next_month }

      it "sends an email with next month's statements and 'none' for this month" do
        expect(UpcomingOutputStatementsMailer).to receive(:email_upcoming_output_statements_mail).with(
          to: contracts_team_email_address,
          this_months_statements: "none",
          next_months_statements: "* deadline date: #{statement_deadline_next_month.deadline_date.to_fs(:govuk)}, cohort: #{cohort_2024.identifier}, statement: March 2026",
        )
        expect(mailer_double).to receive(:deliver_now)

        subject
      end
    end

    context "when there are no output satements for the next month" do
      before { statement_deadline_this_month_march_2024_cohort }

      it "sends an email with this month's statements and 'none' for next month" do
        expect(UpcomingOutputStatementsMailer).to receive(:email_upcoming_output_statements_mail).with(
          to: contracts_team_email_address,
          this_months_statements: "* deadline date: #{today.beginning_of_month.to_fs(:govuk)}, cohort: #{cohort_2024.identifier}, statement: March 2026",
          next_months_statements: "none",
        )
        expect(mailer_double).to receive(:deliver_now)

        subject
      end
    end
  end

  context "when a contracts team email is not configured" do
    before { allow(ENV).to receive(:[]).with("CONTRACTS_TEAM_EMAIL_ADDRESS").and_return(nil) }

    it "does not send an email" do
      expect(UpcomingOutputStatementsMailer).not_to receive(:email_upcoming_output_statements_mail)
      expect(mailer_double).not_to receive(:deliver_now)

      subject
    end
  end
end
