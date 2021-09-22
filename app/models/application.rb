class Application < ApplicationRecord
  belongs_to :user
  belongs_to :course
  belongs_to :lead_provider
  belongs_to :school, foreign_key: "school_urn", primary_key: "urn", optional: true

  def calculate_funding_eligbility
    Services::FundingEligibility.new(course: course, institution: school, headteacher_status: headteacher_status).call
  end
end
