require "rails_helper"

RSpec.describe Services::Report do
  before do
    create(:application, school: nil)
  end

  describe "#call" do
    context "for international applications without a school" do
      it "does not raise an error" do
        expect { subject.call }.not_to raise_error
      end
    end

    it "includes expected headers in CSV" do
      expected_headers = %w[
        user_id
        ecf_user_id
        user_created_at
        trn_verified
        trn_auto_verified
        application_id
        application_ecf_id
        application_created_at
        headteacher_status
        eligible_for_funding
        funding_choice
        funding_eligiblity_status_code
        targeted_delivery_funding_eligibility
        works_in_childcare
        nursery_type
        private_childcare_provider_urn
        cohort
        school_urn
        school_name
        establishment_type_name
        high_pupil_premium
        la_name
        school_postcode
        course_name
        provider_name
      ]

      csv_headers = CSV.parse(subject.call).first

      expect(csv_headers).to match_array(expected_headers)
    end
  end
end
