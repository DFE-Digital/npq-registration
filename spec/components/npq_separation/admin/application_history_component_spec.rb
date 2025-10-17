require "rails_helper"

RSpec.describe NpqSeparation::Admin::ApplicationHistoryComponent, :versioning, type: :component do
  subject { render_inline described_class.new(record: application) }

  let(:application) { create(:application) }
  let(:time_1) { Time.zone.local(2025, 1, 1, 13, 0, 0) }
  let(:time_2) { Time.zone.local(2025, 1, 1, 14, 0, 0) }
  let(:time_3) { Time.zone.local(2025, 1, 1, 15, 0, 0) }
  let(:time_4) { Time.zone.local(2025, 1, 1, 16, 0, 0) }
  let(:cohort) { create(:cohort, start_year: 2024) }
  let(:older_cohort) { create(:cohort, start_year: 2023) }
  let(:whodunnit) { "Admin 1" }

  before do
    PaperTrail.request.whodunnit = whodunnit
    travel_to time_1
  end

  context "when there have been no changes to the record" do
    it { is_expected.to have_text("No changes have been made to this application") }
  end

  context "when there are changes to the record" do
    let(:original_lead_provider) { LeadProvider.first }
    let(:original_itt_provider) { create(:itt_provider) }
    let(:new_lead_provider) { LeadProvider.last }
    let(:original_ecf_id) { SecureRandom.uuid }
    let(:application) { create(:application, :accepted, cohort:, lead_provider: original_lead_provider, itt_provider: original_itt_provider, ecf_id: original_ecf_id) }
    let(:whodunnit) { "some user" }

    before do
      create(:schedule, cohort: older_cohort, course_group: application.course.course_group, identifier: application.schedule.identifier)
      travel_to time_2
      Applications::ChangeCohort.new(application:, cohort_id: older_cohort.id).change_cohort
      travel_to time_3
      Applications::ChangeLeadProvider.new(application:, lead_provider_id: new_lead_provider.id).change_lead_provider
    end

    it "shows an item for each change" do
      expect(subject).to have_css(".moj-timeline .moj-timeline__item .moj-timeline__header h2.moj-timeline__title",
                                  text: "Cohort changed to #{older_cohort.name}")
      expect(subject).to have_css(".moj-timeline .moj-timeline__item .moj-timeline__header h2.moj-timeline__title",
                                  text: "Schedule changed to #{Schedule.last.name}")
      expect(subject).to have_css(".moj-timeline .moj-timeline__item .moj-timeline__header h2.moj-timeline__title",
                                  text: "Provider changed to #{new_lead_provider.name}")
    end

    it "shows the date of each change" do
      expect(subject).to have_css(".moj-timeline__byline", text: "by some user, 1 Jan 2025 2:00pm")
      expect(subject).to have_css(".moj-timeline__byline", text: "by some user, 1 Jan 2025 3:00pm")
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

        it "shows who made the change using the whodunnit string" do
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
                                    text: "Itt provider changed to ID: #{application.itt_provider.id}")
      end
    end

    context "when the change is on _id attribute that is not an association" do
      let(:new_ecf_id) { SecureRandom.uuid }

      before { application.update!(ecf_id: new_ecf_id) }

      it "shows the change using an ID" do
        expect(subject).to have_css(".moj-timeline .moj-timeline__item .moj-timeline__header h2.moj-timeline__title",
                                    text: "Ecf changed to ID: #{new_ecf_id}")
      end
    end
  end

  context "when there is a change to the training_status field with a reason" do
    let(:application) { create(:application, :accepted) }

    before do
      create(:declaration, application:)
      Applications::ChangeTrainingStatus.new(application:, training_status: Application.training_statuses[:deferred], reason: "other").change_training_status
    end

    it "renders the reason with an inset component" do
      expect(subject).to have_css("div.govuk-inset-text", text: "Reason for training status change: other")
    end
  end

  context "when there is a change to the notes field" do
    let(:notes) { "New note added\nTesting123" }

    before do
      travel_to time_4
      application.update!(notes:)
    end

    it "shows the notes have been updated" do
      expect(subject).to have_css(".moj-timeline .moj-timeline__item .moj-timeline__header h2.moj-timeline__title",
                                  text: "Notes updated")
    end

    it "shows who made the change using the whodunnit string and the date of the change" do
      expect(subject).to have_css(".moj-timeline .moj-timeline__item .moj-timeline__header p.moj-timeline__byline",
                                  text: "by #{whodunnit}, 1 Jan 2025 4:00pm")
    end

    it "renders the note with a details component" do
      expect(subject).to have_css(".govuk-details__summary-text", text: "Review notes")
      expect(subject).to have_css(".govuk-details__text", text: notes, visible: :hidden)
    end
  end

  context "when there is a change to funding eligibility" do
    before do
      Applications::ChangeFundingEligibility.new(application:, eligible_for_funding: true).change_funding_eligibility
    end

    it "shows the eligibility funding change" do
      expect(subject).to have_css(".moj-timeline .moj-timeline__item .moj-timeline__header h2.moj-timeline__title",
                                  text: "Eligible for funding changed to yes")
    end

    it "does not show the funding eligibility status code change as a separate item" do
      expect(subject).not_to have_css(".moj-timeline .moj-timeline__item .moj-timeline__header h2.moj-timeline__title",
                                      text: "Funding eligibility status code changed to marked_funded_by_policy")
    end

    it "shows the funding eligibility status code change as a bullet point" do
      expect(subject).to have_css(".govuk-list--bullet",
                                  text: "Status code changed to marked_funded_by_policy")
    end
  end

  # not sure how this happens, but there are plenty of versions like this in production
  context "when there is a version with no object_changes" do
    before do
      Applications::ChangeCohort.new(application:, cohort_id: older_cohort.id).change_cohort
      application.versions.last.update!(object_changes: nil)
    end

    it "does not show the version in the history" do
      expect(subject).not_to have_css(".moj-timeline .moj-timeline__item .moj-timeline__header h2.moj-timeline__title")
    end
  end
end
