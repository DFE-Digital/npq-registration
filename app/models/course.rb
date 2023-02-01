class Course < ApplicationRecord
  COURSE_NAMES = {
    ASO: "Additional Support Offer for new headteachers",
    NPQLT: "NPQ for Leading Teaching (NPQLT)",
    NPQLBC: "NPQ for Leading Behaviour and Culture (NPQLBC)",
    NPQLTD: "NPQ for Leading Teacher Development (NPQLTD)",
    NPQLL: "NPQ for Leading Literacy (NPQLL)",
    NPQSL: "NPQ for Senior Leadership (NPQSL)",
    NPQH: "NPQ for Headship (NPQH)",
    NPQEL: "NPQ for Executive Leadership (NPQEL)",
    NPQEYL: "NPQ for Early Years Leadership (NPQEYL)",
    EHCO: "Early Headship Coaching Offer",
  }.with_indifferent_access.freeze

  LEGACY_NAME_MAPPING = {
    "leading_behaviour_and_culture" => "NPQ for Leading Behaviour and Culture (NPQLBC)",
    "leading_literacy" => "NPQ for Leading Literacy (NPQLL)",
    "leading_teaching" => "NPQ for Leading Teaching (NPQLT)",
    "leading_teacher_development" => "NPQ for Leading Teacher Development (NPQLTD)",
    "senior_leadership" => "NPQ for Senior Leadership (NPQSL)",
    "headship" => "NPQ for Headship (NPQH)",
    "executive_leadership" => "NPQ for Executive Leadership (NPQEL)",
    "early_years_leadership" => "NPQ for Early Years Leadership (NPQEYL)",
    "early_headship_coaching_offer" => "Early Headship Coaching Offer",
  }.with_indifferent_access.freeze

  COURSE_ECF_ID_TO_IDENTIFIER_MAPPING = {
    "15c52ed8-06b5-426e-81a2-c2664978a0dc" => "npq-leading-teaching",
    "7d47a0a6-fa74-4587-92cc-cd1e4548a2e5" => "npq-leading-behaviour-culture",
    "29fee78b-30ce-4b93-ba21-80be2fde286f" => "npq-leading-teaching-development",
    "a42736ad-3d0b-401d-aebe-354ef4c193ec" => "npq-senior-leadership",
    "0f7d6578-a12c-4498-92a0-2ee0f18e0768" => "npq-headship",
    "aef853f2-9b48-4b6a-9d2a-91b295f5ca9a" => "npq-executive-leadership",
    "7fbefdd4-dd2d-4a4f-8995-d59e525124b7" => "npq-additional-support-offer",
    "0222d1a8-a8e1-42e3-a040-2c585f6c194a" => "npq-early-headship-coaching-offer",
    "66dff4af-a518-498f-9042-36a41f9e8aa7" => "npq-early-years-leadership",
    "829fcd45-e39d-49a9-b309-26d26debfa90" => "npq-leading-literacy",
  }.with_indifferent_access.freeze

  scope :aso, -> { where(name: COURSE_NAMES[:ASO]) }
  scope :ehco, -> { where(name: COURSE_NAMES[:EHCO]) }
  scope :npqeyl, -> { where(name: COURSE_NAMES[:NPQEYL]) }

  def self.find_by_code(code:)
    find_by(name: COURSE_NAMES[code])
  end

  def supports_targeted_delivery_funding?
    !ehco? && !aso?
  end

  def npqh?
    name == COURSE_NAMES[:NPQH]
  end

  def aso?
    name == COURSE_NAMES[:ASO]
  end

  def npqsl?
    name == COURSE_NAMES[:NPQSL]
  end

  def ehco?
    name == COURSE_NAMES[:EHCO]
  end

  def eyl?
    name == COURSE_NAMES[:NPQEYL]
  end

  def identifier
    COURSE_ECF_ID_TO_IDENTIFIER_MAPPING[ecf_id]
  end
end
