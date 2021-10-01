class Course < ApplicationRecord
  def studying_for_headship?
    name == "NPQ for Headship (NPQH)"
  end

  def npqh?
    name == "NPQ for Headship (NPQH)"
  end

  def studying_for_aso?
    name == "Additional Support Offer for new headteachers"
  end

  def aso?
    name == "Additional Support Offer for new headteachers"
  end

  def npqsl?
    name == "NPQ for Senior Leadership (NPQSL)"
  end
end
