class Application < ApplicationRecord
  # These columns are no longer populated with data for future applications
  # but are still in place because they contain historical data.
  # This constant is set so that despite still existing they won't be hooked up
  # within the rails model
  self.ignored_columns = %w[DEPRECATED_cohort]

  UK_CATCHMENT_AREA = %w[jersey_guernsey_isle_of_man england northern_ireland scotland wales].freeze
  INELIGIBLE_FOR_FUNDING_REASONS = %w[
    previously-funded
    establishment-ineligible
  ].freeze

  has_paper_trail meta: { note: :version_note }

  belongs_to :user
  belongs_to :course
  belongs_to :lead_provider
  belongs_to :school, optional: true
  belongs_to :private_childcare_provider, optional: true
  belongs_to :private_childcare_provider_including_disabled, -> { including_disabled }, optional: true, class_name: "PrivateChildcareProvider", foreign_key: :private_childcare_provider_id
  belongs_to :itt_provider, optional: true
  belongs_to :itt_provider_including_disabled, -> { including_disabled }, optional: true, class_name: "IttProvider", foreign_key: :itt_provider_id
  belongs_to :cohort, optional: true
  belongs_to :schedule, optional: true

  has_many :ecf_sync_request_logs, as: :syncable, dependent: :destroy
  has_many :participant_id_changes, through: :user
  has_many :application_states
  has_many :declarations

  scope :expired_applications, -> { where(lead_provider_approval_status: "rejected").where("created_at < ?", cut_off_date_for_expired_applications) }
  scope :active_applications, -> { where.not(id: expired_applications) }
  scope :accepted, -> { where(lead_provider_approval_status: "accepted") }
  scope :eligible_for_funding, -> { where(eligible_for_funding: true) }
  scope :with_targeted_delivery_funding_eligibility, -> { where(targeted_delivery_funding_eligibility: true) }

  attr_accessor :version_note, :skip_touch_user_if_changed

  validate :schedule_cohort_matches
  validates :ecf_id, uniqueness: { case_sensitive: false }

  after_commit :touch_user_if_changed

  enum kind_of_nursery: {
    local_authority_maintained_nursery: "local_authority_maintained_nursery",
    preschool_class_as_part_of_school: "preschool_class_as_part_of_school",
    private_nursery: "private_nursery",
    another_early_years_setting: "another_early_years_setting",
    childminder: "childminder",
  }, _suffix: true

  enum headteacher_status: {
    no: "no",
    yes_when_course_starts: "yes_when_course_starts",
    yes_in_first_two_years: "yes_in_first_two_years",
    yes_over_two_years: "yes_over_two_years",
    yes_in_first_five_years: "yes_in_first_five_years",
    yes_over_five_years: "yes_over_five_years",
  }, _suffix: true

  enum funding_choice: {
    school: "school",
    trust: "trust",
    self: "self",
    another: "another",
    employer: "employer",
  }, _suffix: true

  enum lead_provider_approval_status: {
    pending: "pending",
    accepted: "accepted",
    rejected: "rejected",
  }, _suffix: true

  enum training_status: {
    active: "active",
    deferred: "deferred",
    withdrawn: "withdrawn",
  }, _suffix: true

  validates :funded_place, inclusion: { in: [true, false] }, if: :validate_funded_place?
  validate :eligible_for_funded_place
  validate :validate_permitted_schedule_for_course

  # `eligible_for_dfe_funding?`  takes into consideration what we know
  # about user eligibility plus if it has been previously funded. We need
  # to keep this method in place to keep consistency during the split between
  # ECF and NPQ. In the mid term we will perform this calculation on NPQ and
  # store the value in the `eligible_for_funding` attribute.
  def eligible_for_dfe_funding?(with_funded_place: false)
    if previously_funded?
      false
    else
      funding_eligibility(with_funded_place:)
    end
  end

  def previously_funded?
    # This is an optimization used by the API Applications::Query in order
    # to speed up the bulk-retrieval of Applications.
    return transient_previously_funded if respond_to?(:transient_previously_funded)

    @previously_funded ||= user.applications
      .where.not(id:)
      .where(course: course.rebranded_alternative_courses)
      .accepted
      .eligible_for_funding
      .where(funded_place: [nil, true])
      .exists?
  end

  def ineligible_for_funding_reason
    return "previously-funded" if previously_funded?

    "establishment-ineligible" unless eligible_for_funding
  end

  def private_nursery?
    Questionnaires::KindOfNursery::KIND_OF_NURSERY_PRIVATE_OPTIONS.include?(kind_of_nursery)
  end

  def public_nursery?
    Questionnaires::KindOfNursery::KIND_OF_NURSERY_PUBLIC_OPTIONS.include?(kind_of_nursery)
  end

  def synced_to_ecf?
    ecf_id.present?
  end

  def inside_uk_catchment?
    teacher_catchment.in?(UK_CATCHMENT_AREA)
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

  def fundable?
    eligible_for_dfe_funding?(with_funded_place: true)
  end

  def latest_participant_outcome_state
    declarations.completed.billable_or_voidable.latest_first.first&.participant_outcomes&.latest&.state
  end

private

  def funding_eligibility(with_funded_place:)
    return eligible_for_funding unless with_funded_place

    eligible_for_funding && (funded_place.nil? || funded_place)
  end

  def schedule_cohort_matches
    errors.add(:schedule, :cohort_mismatch) if schedule && schedule.cohort != cohort
  end

  def validate_funded_place?
    accepted_lead_provider_approval_status? && errors.blank? && cohort&.funding_cap?
  end

  def eligible_for_funded_place
    return if errors.any?
    return unless cohort&.funding_cap?

    if funded_place && !eligible_for_funding
      errors.add(:funded_place, :not_eligible)
    end
  end

  def validate_permitted_schedule_for_course
    return if errors.any?
    return unless accepted_lead_provider_approval_status? && schedule && course

    unless schedule.course_group.courses.include?(course)
      errors.add(:schedule, :invalid_for_course)
    end
  end

  def touch_user_if_changed
    return if skip_touch_user_if_changed
    return unless saved_change_to_lead_provider_approval_status?

    user.touch(time: updated_at)
  end
end
