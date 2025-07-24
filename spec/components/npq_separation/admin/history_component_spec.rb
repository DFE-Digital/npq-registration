require "rails_helper"

RSpec.describe NpqSeparation::Admin::HistoryComponent, :versioning, type: :component do
  subject { render_inline described_class.new(record: application) }

  let(:application) { create(:application) }
  let(:time_1) { Time.zone.local(2025, 1, 1, 14, 0, 0) }
  let(:time_2) { Time.zone.local(2025, 1, 1, 15, 0, 0) }
  let(:time_3) { Time.zone.local(2025, 1, 1, 16, 0, 0) }
  let(:time_4) { Time.zone.local(2025, 1, 1, 17, 0, 0) }

  before { travel_to time_1 }

  context "when there have been no changes to the record" do
    it { is_expected.to have_text("No changes have been made to this application") }
  end

  context "when there are changes to the record" do
    let(:original_lead_provider) { LeadProvider.first }
    let(:original_itt_provider) { create(:itt_provider) }
    let(:new_lead_provider) { LeadProvider.last }
    let(:original_ecf_id) { SecureRandom.uuid }
    let(:application) { create(:application, :accepted, cohort:, lead_provider: original_lead_provider, itt_provider: original_itt_provider, ecf_id: original_ecf_id) }
    let(:cohort) { create(:cohort, start_year: 2024) }
    let(:older_cohort) { create(:cohort, start_year: 2023) }
    let(:whodunnit) { nil }

    before do
      PaperTrail.request.whodunnit = whodunnit
      create(:schedule, cohort: older_cohort, course_group: application.course.course_group, identifier: application.schedule.identifier)
      travel_to time_2
      Applications::ChangeCohort.new(application:, cohort_id: older_cohort.id).change_cohort
      travel_to time_3
      Applications::ChangeLeadProvider.new(application:, lead_provider_id: new_lead_provider.id).change_lead_provider
      travel_to time_4
      Applications::ChangeFundingEligibility.new(application:, eligible_for_funding: true).change_funding_eligibility
    end

    it "shows an item for each change" do
      expect(subject).to have_css(".moj-timeline .moj-timeline__item .moj-timeline__header h2.moj-timeline__title",
                                  text: "Cohort changed from 2024 to 2023, Schedule changed from #{Schedule.first.name} to #{Schedule.last.name}")
      expect(subject).to have_css(".moj-timeline .moj-timeline__item .moj-timeline__header h2.moj-timeline__title",
                                  text: "Provider changed from #{original_lead_provider.name} to #{new_lead_provider.name}")
      expect(subject).to have_css(".moj-timeline .moj-timeline__item .moj-timeline__header h2.moj-timeline__title",
                                  text: "Eligible for funding changed to true, Funding eligibility status code changed to marked_funded_by_policy")
    end

    it "shows the date of each change" do
      expect(subject).to have_css(".moj-timeline .moj-timeline__item .moj-timeline__date time",
                                  text: "1 Jan 2025 3:00pm")
      expect(subject).to have_css(".moj-timeline .moj-timeline__item .moj-timeline__date time",
                                  text: "1 Jan 2025 4:00pm")
      expect(subject).to have_css(".moj-timeline .moj-timeline__item .moj-timeline__date time",
                                  text: "1 Jan 2025 5:00pm")
    end

    context "when the user is an Admin" do
      let(:admin) { create(:admin) }
      let(:whodunnit) { "Admin #{admin.id}" }

      it "shows the admin user who made the changes" do
        expect(subject).to have_css(".moj-timeline .moj-timeline__item .moj-timeline__header p.moj-timeline__byline",
                                    text: "by #{admin.full_name}")
      end

      context "when the admin user has been deleted" do
        before { admin.destroy }

        it "shows the change using the whodunnit string" do
          expect(subject).to have_css(".moj-timeline .moj-timeline__item .moj-timeline__header p.moj-timeline__byline",
                                      text: "by #{whodunnit}")
        end
      end
    end

    context "when the user is a Lead Provider" do
      let(:whodunnit) { "Lead provider #{original_lead_provider.id}" }

      it "shows the lead provider who made the changes" do
        expect(subject).to have_css(".moj-timeline .moj-timeline__item .moj-timeline__header p.moj-timeline__byline",
                                    text: "by #{original_lead_provider.name}")
      end
    end

    context "when the user is a public user" do
      let(:whodunnit) { "Public User #{application.user.id}" }

      it "shows the user who made the changes" do
        expect(subject).to have_css(".moj-timeline .moj-timeline__item .moj-timeline__header p.moj-timeline__byline",
                                    text: "by #{application.user.full_name}")
      end
    end

    context "when the user is another type of user" do
      let(:whodunnit) { "some other user" }

      it "shows the user who made the changes" do
        expect(subject).to have_css(".moj-timeline .moj-timeline__item .moj-timeline__header p.moj-timeline__byline",
                                    text: "by some other user")
      end
    end

    context "when the user is nil" do
      let(:whodunnit) { nil }

      it "shows the user who made the changes as 'unknown'" do
        expect(subject).to have_css(".moj-timeline .moj-timeline__item .moj-timeline__header p.moj-timeline__byline",
                                    text: "by unknown")
      end
    end

    context "when the change is on an association with no name attribute" do
      before { application.update!(itt_provider: create(:itt_provider)) }

      it "shows the change using an ID" do
        expect(subject).to have_css(".moj-timeline .moj-timeline__item .moj-timeline__header h2.moj-timeline__title",
                                    text: "Itt provider changed from ID: #{original_itt_provider.id} to ID: #{application.itt_provider.id}")
      end
    end

    context "when the change is on _id attribute that is not an association" do
      let(:new_ecf_id) { SecureRandom.uuid }

      before { application.update!(ecf_id: new_ecf_id) }

      it "shows the change using an ID" do
        expect(subject).to have_css(".moj-timeline .moj-timeline__item .moj-timeline__header h2.moj-timeline__title",
                                    text: "Ecf changed from ID: #{original_ecf_id} to ID: #{new_ecf_id}")
      end
    end
  end
end
