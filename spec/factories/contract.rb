FactoryBot.define do
  factory :contract do
    transient do
      cohort { create(:cohort) }
      lead_provider { LeadProvider.all.sample }
    end

    statement { association :statement, cohort:, lead_provider: }
    course
    recruitment_target { 72 }
    per_participant { 800.00 }
    number_of_payment_periods { 3 }
    output_payment_percentage { 60 }
    service_fee_installments { 19 }
    service_fee_percentage { 40 }
    monthly_service_fee { 0.0 }
    targeted_delivery_funding_per_participant { 100.0 }

    trait :npq_early_headship_coaching_offer do
      course { Course.find_by!(identifier: "npq-early-headship-coaching-offer") }
      recruitment_target { 180 }
      number_of_payment_periods { 4 }
      per_participant { 740.00 }
      service_fee_installments { 20 }
    end

    trait :npq_early_years_leadership do
      course { Course.find_by!(identifier: "npq-early-years-leadership") }
      recruitment_target { 172 }
      number_of_payment_periods { 4 }
      per_participant { 840.00 }
      service_fee_installments { 31 }
    end

    trait :npq_executive_leadership do
      course { Course.find_by!(identifier: "npq-executive-leadership") }
      recruitment_target { 26 }
      number_of_payment_periods { 4 }
      per_participant { 850.00 }
      service_fee_installments { 25 }
    end

    trait :npq_headship do
      course { Course.find_by!(identifier: "npq-headship") }
      recruitment_target { 222 }
      number_of_payment_periods { 4 }
      per_participant { 540.00 }
      service_fee_installments { 21 }
    end

    trait :npq_leading_behaviour_culture do
      course { Course.find_by!(identifier: "npq-leading-behaviour-culture") }
      recruitment_target { 72 }
      number_of_payment_periods { 3 }
      per_participant { 810.00 }
      service_fee_installments { 19 }
    end

    trait :npq_leading_literacy do
      course { Course.find_by!(identifier: "npq-leading-literacy") }
      recruitment_target { 82 }
      number_of_payment_periods { 4 }
      per_participant { 710.00 }
      service_fee_installments { 20 }
    end

    trait :npq_leading_primary_mathematics do
      course { Course.find_by!(identifier: "npq-leading-primary-mathematics") }
      recruitment_target { 400 }
      number_of_payment_periods { 3 }
      per_participant { 902.00 }
      service_fee_installments { 540 }
    end

    trait :npq_leading_teaching do
      course { Course.find_by(identifier: "npq-leading-teaching") }
      recruitment_target { 102 }
      number_of_payment_periods { 3 }
      service_fee_installments { 29 }
      per_participant { 810.00 }
    end

    trait :npq_leading_teaching_development do
      course { Course.find_by!(identifier: "npq-leading-teaching-development") }
      recruitment_target { 211 }
      number_of_payment_periods { 3 }
      per_participant { 820.00 }
      service_fee_installments { 19 }
    end

    trait :npq_senior_leadership do
      course { Course.find_by!(identifier: "npq-senior-leadership") }
      recruitment_target { 205 }
      number_of_payment_periods { 4 }
      per_participant { 830.00 }
      service_fee_installments { 25 }
    end

    trait :npq_senco do
      course { Course.find_by!(identifier: "npq-senco") }
      recruitment_target { 301 }
      number_of_payment_periods { 3 }
      per_participant { 630.00 }
      service_fee_installments { 22 }
    end

    trait :npq_additional_support_offer do
      course { Course.find_by!(identifier: "npq-additional-support-offer") }
      recruitment_target { 301 }
      number_of_payment_periods { 4 }
      per_participant { 430.00 }
      service_fee_installments { 15 }
    end
  end
end
