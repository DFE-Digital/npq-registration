# frozen_string_literal: true

FactoryBot.define do
  factory :parity_check_comparison, class: "Migration::ParityCheckComparison" do
    path { "/path" }

    method { "GET" }
    ecf_status { 200 }
    npq_status { 200 }
    ecf_response { { "key" => "value" } }
    npq_response { { "key" => "value" } }
    equal { true }
  end
end
