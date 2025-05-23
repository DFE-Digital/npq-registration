class LeadProvider < ApplicationRecord
  ALL_ACTIVE_PROVIDERS = {
    "Ambition Institute" => "9e35e998-c63b-4136-89c4-e9e18ddde0ea",
    "Best Practice Network" => "57ba9e86-559f-4ff4-a6d2-4610c7259b67",
    "Church of England" => "79cb41ca-cb6d-405c-b52c-b6f7c752388d",
    "LLSE" => "230e67c0-071a-4a48-9673-9d043d456281",
    "National Institute of Teaching" => "3ec607f2-7a3a-421f-9f1a-9aca8a634aeb",
    "School-Led Network" => "bc5e4e37-1d64-4149-a06b-ad10d3c55fd0",
    "Teach First" => "a02ae582-f939-462f-90bc-cebf20fa8473",
    "UCL Institute of Education" => "ef687b3d-c1c0-4566-a295-16d6fa5d0fa7",
  }.freeze

  NPQH_SL_LT_LTD_LBC_PROVIDERS = [
    "Ambition Institute",
    "Best Practice Network",
    "Church of England",
    "LLSE",
    "National Institute of Teaching",
    "Teach First",
    "UCL Institute of Education",
  ].freeze

  NPQH_EHCO_PROVIDERS = [
    "Ambition Institute",
    "Best Practice Network",
    "Church of England",
    "National Institute of Teaching",
    "Teach First",
    "LLSE",
    "UCL Institute of Education",
  ].freeze

  EYL_LL_PROVIDERS = [
    "Ambition Institute",
    "National Institute of Teaching",
    "Teach First",
    "UCL Institute of Education",
  ].freeze

  EL_PROVIDERS = [
    "Ambition Institute",
    "Best Practice Network",
    "Church of England",
    "LLSE",
    "National Institute of Teaching",
    "Teach First",
    "UCL Institute of Education",
  ].freeze

  LPM_PROVIDERS = [
    "Ambition Institute",
    "Church of England",
    "LLSE",
    "Teach First",
    "UCL Institute of Education",
    "National Institute of Teaching",
  ].freeze

  SENCO_PROVIDERS = [
    "Ambition Institute",
    "Best Practice Network",
    "Church of England",
    "National Institute of Teaching",
    "Teach First",
    "UCL Institute of Education",
  ].freeze

  # TODO: Move all of this mapping into the database
  #       Hardcoding this has been done for expediency but
  #       longterm having this handled in the DB so none of
  #       this data has to be hardcoded would be preferable.
  COURSE_TO_PROVIDER_MAPPING = {
    "npq-headship" => NPQH_SL_LT_LTD_LBC_PROVIDERS,
    "npq-senior-leadership" => NPQH_SL_LT_LTD_LBC_PROVIDERS,
    "npq-leading-teaching" => NPQH_SL_LT_LTD_LBC_PROVIDERS,
    "npq-leading-teaching-development" => NPQH_SL_LT_LTD_LBC_PROVIDERS,
    "npq-leading-behaviour-culture" => NPQH_SL_LT_LTD_LBC_PROVIDERS,
    "npq-early-headship-coaching-offer" => NPQH_EHCO_PROVIDERS,
    "npq-additional-support-offer" => NPQH_SL_LT_LTD_LBC_PROVIDERS,
    "npq-early-years-leadership" => EYL_LL_PROVIDERS,
    "npq-leading-literacy" => EYL_LL_PROVIDERS,
    "npq-executive-leadership" => EL_PROVIDERS,
    "npq-leading-primary-mathematics" => LPM_PROVIDERS,
    "npq-senco" => SENCO_PROVIDERS,
  }.freeze

  has_many :applications
  has_many :statements

  has_many :delivery_partnerships
  has_many :delivery_partners, through: :delivery_partnerships

  validates :name, presence: true
  validates :ecf_id, uniqueness: { case_sensitive: false }, allow_nil: true

  scope :alphabetical, -> { order(name: :asc) }

  def self.for(course:)
    course_specific_list = COURSE_TO_PROVIDER_MAPPING[course.identifier]

    return all if course_specific_list.blank?

    ecf_ids = ALL_ACTIVE_PROVIDERS.slice(*course_specific_list).values.compact_blank
    raise "Missing provider ECF_ID for available providers list" if ecf_ids.count != course_specific_list.count

    where(ecf_id: ecf_ids)
  end

  def next_output_fee_statement(cohort)
    statements.next_output_fee_statements.where(cohort:).first
  end

  def delivery_partners_for_cohort(cohort)
    delivery_partners.where(delivery_partnerships: { cohort: })
  end
end
