FactoryBot.define do
  factory :ecf_npq_course, class: "Migration::Ecf::NpqCourse" do
    sequence(:name) { |n| "NPQ Course #{n}" }
    identifier { "npq-headship" }
  end
end
