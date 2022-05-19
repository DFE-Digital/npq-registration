class Course < ApplicationRecord
  COURSE_NAMES = {
    NPQLT: "NPQ Leading Teaching (NPQLT)",
    NPQLBC: "NPQ Leading Behaviour and Culture (NPQLBC)",
    NPQLTD: "NPQ Leading Teacher Development (NPQLTD)",
    NPQSL: "NPQ for Senior Leadership (NPQSL)",
    NPQH: "NPQ for Headship (NPQH)",
    NPQEL: "NPQ for Executive Leadership (NPQEL)",
    ASO: "Additional Support Offer for new headteachers",
    EHCO: "The Early Headship Coaching Offer",
    NPQEYL: "NPQ Early Years Leadership (NPQEYL)",
    NPQLL: "NPQ Leading Literacy (NPQLL)",
  }.with_indifferent_access.freeze

  scope :ehco, -> { where(name: "The Early Headship Coaching Offer") }

  def npqh?
    name == "NPQ for Headship (NPQH)"
  end

  def aso?
    name == "Additional Support Offer for new headteachers"
  end

  def npqsl?
    name == "NPQ for Senior Leadership (NPQSL)"
  end

  def ehco?
    name == "The Early Headship Coaching Offer"
  end
end
