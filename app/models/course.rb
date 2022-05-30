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

  scope :ehco, -> { where(name: "Early Headship Coaching Offer") }

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
    name == "Early Headship Coaching Offer"
  end

  def eyl?
    name == "NPQ for Early Years Leadership (NPQEYL)"
  end
end
