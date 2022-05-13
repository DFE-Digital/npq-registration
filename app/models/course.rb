class Course < ApplicationRecord
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

  def eyl?
    name == "NPQ Early Years Leadership (NPQEYL)"
  end
end
