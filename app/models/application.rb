class Application < ApplicationRecord
  # These columns are no longer populated with data for future applications
  # but are still in place because they contain historical data.
  # This constant is set so that despite still existing they won't be hooked up
  # within the rails model
  self.ignored_columns = %w[DEPRECATED_cohort]

  has_paper_trail only: %i[lead_provider_approval_status participant_outcome_state]

  belongs_to :user
  belongs_to :course
  belongs_to :lead_provider
  belongs_to :school, optional: true
  belongs_to :private_childcare_provider, optional: true
  belongs_to :itt_provider, optional: true
  belongs_to :cohort, optional: true
  belongs_to :eligible_for_funding_updated_by, class_name: "User", optional: true

  has_many :ecf_sync_request_logs, as: :syncable, dependent: :destroy

  scope :unsynced, -> { where(ecf_id: nil) }
  scope :expired_applications, -> { where(lead_provider_approval_status: "rejected").where("created_at < ?", cut_off_date_for_expired_applications) }
  scope :active_applications, -> { where.not(id: expired_applications) }

  enum kind_of_nursery: {
    local_authority_maintained_nursery: "local_authority_maintained_nursery",
    preschool_class_as_part_of_school: "preschool_class_as_part_of_school",
    private_nursery: "private_nursery",
    another_early_years_setting: "another_early_years_setting",
  }

  def private_nursery?
    Questionnaires::KindOfNursery::KIND_OF_NURSERY_PRIVATE_OPTIONS.include?(kind_of_nursery)
  end

  def public_nursery?
    Questionnaires::KindOfNursery::KIND_OF_NURSERY_PUBLIC_OPTIONS.include?(kind_of_nursery)
  end

  def synced_to_ecf?
    ecf_id.present?
  end

  def inside_catchment?
    %w[england].include?(teacher_catchment)
  end

  def new_headteacher?
    %w[yes_when_course_starts yes_in_first_five_years yes_in_first_two_years].include?(headteacher_status)
  end

  def employer_name_to_display
    employer_name || private_childcare_provider&.provider_name || school&.name || ""
  end

  def long_employer_name_to_display
    employer_name ||
      private_childcare_provider&.long_name ||
      school&.long_name ||
      ""
  end

  def employer_urn
    private_childcare_provider&.urn || school_urn || ""
  end

  def school_urn
    school&.urn
  end

  def get_approval_status
    case lead_provider_approval_status
    when "accepted" then "rejected"
    when "rejected" then "pending"
    else "accepted"
    end
  end

  def get_participant_outcome_state
    case participant_outcome_state
    when "passed" then "failed"
    else "passed"
    end
  end

  def self.cut_off_date_for_expired_applications
    Time.zone.local(2024, 6, 30)
  end
end
