FactoryBot.define do
  factory :contract_template do
    service_fee_percentage { 40 }
    output_payment_percentage { 60 }
    per_participant { 800.00 }
    number_of_payment_periods { 3 }
    recruitment_target { 72 }
    service_fee_installments { 19 }
    targeted_delivery_funding_per_participant { 100.0 }
    monthly_service_fee { 0.0 }
    special_course { false }
  end
end
