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

  scope :ehco, -> { where(name: COURSE_NAMES[:EHCO]) }

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
end
