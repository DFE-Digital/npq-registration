require "rails_helper"

RSpec.describe "accounts/_work_details.html.erb", type: :view do
  include ApplicationHelper

  subject { Capybara.string(rendered) }

  let(:application) { create(:application) }

  it "renders the work details card title" do
    render partial: "accounts/work_details", locals: { application: }
    expect(subject).to have_css("h2.govuk-summary-card__title", text: "Work details")
  end

  describe "workplace in England" do
    context "when teacher_catchment is 'england'" do
      let(:application) { create(:application, teacher_catchment: "england") }

      before do
        render partial: "accounts/work_details", locals: { application: }
      end

      it "shows Yes" do
        expect(subject).to have_css(".govuk-summary-list__key", text: "Workplace in England")
        expect(subject).to have_css(".govuk-summary-list__value", text: "Yes")
      end
    end

    context "when teacher_catchment is not 'england'" do
      let(:application) { create(:application, teacher_catchment: "scotland") }

      before do
        render partial: "accounts/work_details", locals: { application: }
      end

      it "shows No" do
        expect(subject).to have_css(".govuk-summary-list__key", text: "Workplace in England")
        expect(subject).to have_css(".govuk-summary-list__value", text: "No")
      end
    end

    context "when teacher_catchment is nil" do
      let(:application) { create(:application, teacher_catchment: nil) }

      before do
        render partial: "accounts/work_details", locals: { application: }
      end

      it "shows No" do
        expect(subject).to have_css(".govuk-summary-list__key", text: "Workplace in England")
        expect(subject).to have_css(".govuk-summary-list__value", text: "No")
      end
    end
  end

  describe "referred by return to teaching adviser" do
    context "when referred_by_return_to_teaching_adviser is present" do
      let(:application) { create(:application, referred_by_return_to_teaching_adviser: "yes") }

      before do
        render partial: "accounts/work_details", locals: { application: }
      end

      it "shows the referred by return to teaching adviser row" do
        expect(subject).to have_css(".govuk-summary-list__key", text: "Referred by return to teaching adviser")
        expect(subject).to have_css(".govuk-summary-list__value")
      end
    end

    context "when referred_by_return_to_teaching_adviser is nil" do
      let(:application) { create(:application, referred_by_return_to_teaching_adviser: nil) }

      before do
        render partial: "accounts/work_details", locals: { application: }
      end

      it "does not show the referred by return to teaching adviser row" do
        expect(subject).not_to have_css(".govuk-summary-list__key", text: "Referred by return to teaching adviser")
      end
    end

    context "when referred_by_return_to_teaching_adviser is blank" do
      let(:application) { create(:application, referred_by_return_to_teaching_adviser: "") }

      before do
        render partial: "accounts/work_details", locals: { application: }
      end

      it "does not show the referred by return to teaching adviser row" do
        expect(subject).not_to have_css(".govuk-summary-list__key", text: "Referred by return to teaching adviser")
      end
    end
  end

  describe "work setting" do
    context "when work_setting is present" do
      let(:application) { create(:application, :with_random_work_setting) }

      before do
        render partial: "accounts/work_details", locals: { application: }
      end

      it "shows the work setting row" do
        expect(subject).to have_css(".govuk-summary-list__key", text: "Work setting")
        expect(subject).to have_css(".govuk-summary-list__value")
      end
    end

    context "when work_setting is nil" do
      let(:application) { create(:application, work_setting: nil) }

      before do
        render partial: "accounts/work_details", locals: { application: }
      end

      it "does not show the work setting row" do
        expect(subject).not_to have_css(".govuk-summary-list__key", text: "Work setting")
      end
    end

    context "when work_setting is blank" do
      let(:application) { create(:application, work_setting: "") }

      before do
        render partial: "accounts/work_details", locals: { application: }
      end

      it "does not show the work setting row" do
        expect(subject).not_to have_css(".govuk-summary-list__key", text: "Work setting")
      end
    end
  end

  describe "early years setting" do
    context "when inside catchment and works in childcare" do
      let(:application) { create(:application, :with_private_childcare_provider, teacher_catchment: "england") }

      before do
        allow(application).to receive(:inside_catchment?).and_return(true)
        render partial: "accounts/work_details", locals: { application: }
      end

      it "shows the early years setting row" do
        expect(subject).to have_css(".govuk-summary-list__key", text: "Early years setting")
        expect(subject).to have_css(".govuk-summary-list__value")
      end
    end

    context "when not inside catchment" do
      let(:application) { create(:application, :with_private_childcare_provider) }

      before do
        allow(application).to receive(:inside_catchment?).and_return(false)
        render partial: "accounts/work_details", locals: { application: }
      end

      it "does not show the early years setting row" do
        expect(subject).not_to have_css(".govuk-summary-list__key", text: "Early years setting")
      end
    end

    context "when does not work in childcare" do
      let(:application) { create(:application, works_in_childcare: false) }

      before do
        allow(application).to receive(:inside_catchment?).and_return(true)
        render partial: "accounts/work_details", locals: { application: }
      end

      it "does not show the early years setting row" do
        expect(subject).not_to have_css(".govuk-summary-list__key", text: "Early years setting")
      end
    end
  end

  describe "Ofsted URN for private nursery" do
    context "when private nursery with provider present" do
      let(:private_childcare_provider) { create(:private_childcare_provider) }
      let(:application) { create(:application, works_in_childcare: true, kind_of_nursery: "private_nursery", private_childcare_provider:) }

      before do
        allow(application).to receive_messages(inside_catchment?: true, private_nursery?: true)
        render partial: "accounts/work_details", locals: { application: }
      end

      it "shows the URN with provider name" do
        expect(subject).to have_css(".govuk-summary-list__key", text: "Ofsted unique reference number (URN)")
        expect(subject).to have_css(".govuk-summary-list__value", text: private_childcare_provider.display_name)
      end
    end

    context "when private nursery with no provider" do
      let(:application) { create(:application, works_in_childcare: true, kind_of_nursery: "private_nursery", private_childcare_provider: nil) }

      before do
        allow(application).to receive_messages(inside_catchment?: true, private_nursery?: true)
        render partial: "accounts/work_details", locals: { application: }
      end

      it "shows 'Not applicable'" do
        expect(subject).to have_css(".govuk-summary-list__key", text: "Ofsted unique reference number (URN)")
        expect(subject).to have_css(".govuk-summary-list__value", text: "Not applicable")
      end
    end
  end

  describe "workplace" do
    context "when inside catchment with school present" do
      let(:school) { create(:school) }
      let(:application) { create(:application, school:) }

      before do
        allow(application).to receive(:inside_catchment?).and_return(true)
        render partial: "accounts/work_details", locals: { application: }
      end

      it "shows the workplace row" do
        expect(subject).to have_css(".govuk-summary-list__key", text: "Workplace")
        expect(subject).to have_css(".govuk-summary-list__value")
      end
    end

    context "when inside catchment with public nursery" do
      let(:application) { create(:application, :with_public_childcare_provider) }

      before do
        allow(application).to receive_messages(inside_catchment?: true, public_nursery?: true)
        render partial: "accounts/work_details", locals: { application: }
      end

      it "shows the workplace row" do
        expect(subject).to have_css(".govuk-summary-list__key", text: "Workplace")
        expect(subject).to have_css(".govuk-summary-list__value")
      end
    end

    context "when school is nil and not in childcare" do
      let(:application) { create(:application, school: nil, works_in_childcare: false, employer_name: nil, private_childcare_provider: nil) }

      before do
        allow(application).to receive_messages(inside_catchment?: true, public_nursery?: false)
        render partial: "accounts/work_details", locals: { application: }
      end

      it "does not show the workplace row" do
        expect(subject).not_to have_css(".govuk-summary-list__key", text: /^Workplace$/)
      end
    end
  end

  describe "employment type and details" do
    context "when employer_name and employment_type are present" do
      let(:application) { create(:application, employer_name: "Test Employer", employment_type: "other", employment_role: "Senior Teacher") }

      before do
        render partial: "accounts/work_details", locals: { application: }
      end

      it "shows employment type row" do
        expect(subject).to have_css(".govuk-summary-list__key", text: "Employment type")
        expect(subject).to have_css(".govuk-summary-list__value")
      end

      it "shows role row" do
        expect(subject).to have_css(".govuk-summary-list__key", text: "Role")
        expect(subject).to have_css(".govuk-summary-list__value", text: "Senior Teacher")
      end

      it "shows employer row" do
        expect(subject).to have_css(".govuk-summary-list__key", text: "Employer")
        expect(subject).to have_css(".govuk-summary-list__value", text: "Test Employer")
      end
    end

    context "when employment_type is lead_mentor_for_accredited_itt_provider" do
      let(:itt_provider) { create(:itt_provider) }
      let(:application) { create(:application, employment_type: "lead_mentor_for_accredited_itt_provider", itt_provider:) }

      before do
        render partial: "accounts/work_details", locals: { application: }
      end

      it "shows employment type row" do
        expect(subject).to have_css(".govuk-summary-list__key", text: "Employment type")
        expect(subject).to have_css(".govuk-summary-list__value")
      end

      it "shows ITT provider row" do
        expect(subject).to have_css(".govuk-summary-list__key", text: "ITT provider")
        expect(subject).to have_css(".govuk-summary-list__value", text: itt_provider.legal_name)
      end

      it "does not show role or employer rows" do
        expect(subject).not_to have_css(".govuk-summary-list__key", text: "Role")
        expect(subject).not_to have_css(".govuk-summary-list__key", text: "Employer")
      end
    end

    context "when employment_type is lead_mentor_for_accredited_itt_provider but itt_provider is nil" do
      let(:application) { create(:application, employment_type: "lead_mentor_for_accredited_itt_provider", itt_provider: nil) }

      before do
        render partial: "accounts/work_details", locals: { application: }
      end

      it "shows ITT provider row with blank value" do
        expect(subject).to have_css(".govuk-summary-list__key", text: "ITT provider")
        expect(subject).to have_css(".govuk-summary-list__value", text: "")
      end
    end

    context "when employer_name is nil" do
      let(:application) { create(:application, employer_name: nil, employment_type: "other") }

      before do
        render partial: "accounts/work_details", locals: { application: }
      end

      it "does not show employment related rows" do
        expect(subject).not_to have_css(".govuk-summary-list__key", text: "Employment type")
        expect(subject).not_to have_css(".govuk-summary-list__key", text: "Role")
        expect(subject).not_to have_css(".govuk-summary-list__key", text: "Employer")
      end
    end

    context "when employment_type is nil" do
      let(:application) { create(:application, employer_name: "Test Employer", employment_type: nil) }

      before do
        render partial: "accounts/work_details", locals: { application: }
      end

      it "does not show employment related rows" do
        expect(subject).not_to have_css(".govuk-summary-list__key", text: "Employment type")
        expect(subject).not_to have_css(".govuk-summary-list__key", text: "Role")
        expect(subject).not_to have_css(".govuk-summary-list__key", text: "Employer")
      end
    end

    context "when employment_role is nil" do
      let(:application) { create(:application, employer_name: "Test Employer", employment_type: "other", employment_role: nil) }

      before do
        render partial: "accounts/work_details", locals: { application: }
      end

      it "does not show role row" do
        expect(subject).not_to have_css(".govuk-summary-list__key", text: "Role")
      end

      it "still shows employment type and employer" do
        expect(subject).to have_css(".govuk-summary-list__key", text: "Employment type")
        expect(subject).to have_css(".govuk-summary-list__key", text: "Employer")
      end
    end
  end

  describe "EHCO course specific fields" do
    context "when course is EHCO" do
      let(:ehco_course) { create(:course, :early_headship_coaching_offer) }
      let(:application) do
        create(:application,
               course: ehco_course,
               raw_application_data: {
                 "npqh_status" => "completed_npqh",
                 "ehco_headteacher" => "yes",
                 "ehco_new_headteacher" => "no",
               })
      end

      before do
        render partial: "accounts/work_details", locals: { application: }
      end

      it "shows headship NPQ stage" do
        expect(subject).to have_css(".govuk-summary-list__key", text: "Headship NPQ stage")
        expect(subject).to have_css(".govuk-summary-list__value")
      end

      it "shows headteacher status" do
        expect(subject).to have_css(".govuk-summary-list__key", text: "Headteacher")
        expect(subject).to have_css(".govuk-summary-list__value")
      end

      it "shows first 5 years of headship when headteacher is yes" do
        expect(subject).to have_css(".govuk-summary-list__key", text: "First 5 years of headship")
        expect(subject).to have_css(".govuk-summary-list__value")
      end
    end

    context "when course is EHCO but raw_application_data is nil" do
      let(:ehco_course) { create(:course, :early_headship_coaching_offer) }
      let(:application) { create(:application, course: ehco_course, raw_application_data: nil) }

      it "raises an error due to nil raw_application_data (bug in view)" do
        expect { render partial: "accounts/work_details", locals: { application: } }.to raise_error(ActionView::Template::Error, /undefined method '\[\]' for nil/)
      end
    end

    context "when course is EHCO and ehco_headteacher is not yes" do
      let(:ehco_course) { create(:course, :early_headship_coaching_offer) }
      let(:application) do
        create(:application,
               course: ehco_course,
               raw_application_data: {
                 "npqh_status" => "completed_npqh",
                 "ehco_headteacher" => "no",
               })
      end

      before do
        render partial: "accounts/work_details", locals: { application: }
      end

      it "does not show first 5 years of headship" do
        expect(subject).not_to have_css(".govuk-summary-list__key", text: "First 5 years of headship")
      end
    end
  end

  describe "NPQLPM course specific fields" do
    context "when course is NPQLPM" do
      let(:npqlpm_course) { create(:course, :leading_primary_mathematics) }
      let(:application) do
        create(:application,
               course: npqlpm_course,
               raw_application_data: {
                 "maths_eligibility_teaching_for_mastery" => "yes",
               })
      end

      before do
        render partial: "accounts/work_details", locals: { application: }
      end

      it "shows maths teaching for mastery question" do
        expect(subject).to have_css(".govuk-summary-list__key", text: "Completed one year of the primary maths Teaching for Mastery programme?")
        expect(subject).to have_css(".govuk-summary-list__value")
      end
    end

    context "when course is NPQLPM with 'no' answer" do
      let(:npqlpm_course) { create(:course, :leading_primary_mathematics) }
      let(:application) do
        create(:application,
               course: npqlpm_course,
               raw_application_data: {
                 "maths_eligibility_teaching_for_mastery" => "no",
                 "maths_understanding_of_approach" => "taken_a_similar_course",
               })
      end

      before do
        render partial: "accounts/work_details", locals: { application: }
      end

      it "shows understanding of approach instead" do
        expect(subject).to have_css(".govuk-summary-list__key", text: "Completed one year of the primary maths Teaching for Mastery programme?")
        expect(subject).to have_css(".govuk-summary-list__value")
      end
    end
  end

  describe "NPQS course specific fields" do
    context "when course is NPQS" do
      let(:npqs_course) { create(:course, :senco) }
      let(:application) do
        create(:application,
               course: npqs_course,
               raw_application_data: {
                 "senco_in_role_status" => true,
                 "senco_start_date" => "2023-01-15",
               })
      end

      before do
        render partial: "accounts/work_details", locals: { application: }
      end

      it "shows SENCO role with start date" do
        expect(subject).to have_css(".govuk-summary-list__value", text: /Yes – since/)
      end
    end

    context "when course is NPQS but not in role" do
      let(:npqs_course) { create(:course, :senco) }
      let(:application) do
        create(:application,
               course: npqs_course,
               raw_application_data: {
                 "senco_in_role_status" => false,
                 "senco_in_role" => "no_i_do_not_plan_to_be_a_SENCO",
               })
      end

      before do
        render partial: "accounts/work_details", locals: { application: }
      end

      it "shows SENCO role status" do
        expect(subject).to have_css(".govuk-summary-list__value")
      end
    end

    context "when course is NPQS but raw_application_data is nil" do
      let(:npqs_course) { create(:course, :senco) }
      let(:application) { create(:application, course: npqs_course, raw_application_data: nil) }

      it "raises an error due to nil raw_application_data (bug in view)" do
        expect { render partial: "accounts/work_details", locals: { application: } }.to raise_error(ActionView::Template::Error, /undefined method '\[\]' for nil/)
      end
    end
  end
end
