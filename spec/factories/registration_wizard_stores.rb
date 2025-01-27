FactoryBot.define do
  factory :registration_wizard_store, class: Hash do
    initialize_with { attributes.stringify_keys }

    transient do
      course { create(Course::IDENTIFIERS.first.to_sym) }
      school { create(:school, :funding_eligible_establishment_type_code) }
      lead_provider { LeadProvider.first }
      current_user { create(:user) }
    end

    course_identifier { course.identifier }
    institution_identifier { "School-#{school.urn}" }
    lead_provider_id { lead_provider.id }
    works_in_school { "yes" }
    teacher_catchment { "england" }
    work_setting { "a_school" }
    referred_by_return_to_teaching_adviser { "no" }
    senco_in_role { "yes" }
    senco_start_date { "2024-12-12" }
    trn { current_user.trn }
  end
end
