class Application < ApplicationRecord
  TARGET_COHORT = 2022

  belongs_to :user
  belongs_to :course
  belongs_to :lead_provider
  belongs_to :school, foreign_key: "school_urn", primary_key: "urn", optional: true

  enum kind_of_nursery: {
    local_authority_maintained_nursery: "local_authority_maintained_nursery",
    preschool_class_as_part_of_school: "preschool_class_as_part_of_school",
    private_nursery: "private_nursery",
  }

  def calculate_funding_eligbility
    Services::FundingEligibility.new(
      course: course,
      institution: school,
      inside_catchment: inside_catchment?,
      new_headteacher: new_headteacher?,
    ).funded?
  end

  def inside_catchment?
    %w[england].include?(teacher_catchment)
  end

  def new_headteacher?
    %w[yes_when_course_starts yes_in_first_five_years yes_in_first_two_years].include?(headteacher_status)
  end
end
