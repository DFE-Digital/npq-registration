class Course < ApplicationRecord
  def npqh?
    name == "NPQ for Headship (NPQH)"
  end

  def aso?
    name == "Additional Support Offer for new headteachers"
  end

  def npqsl?
    name == "NPQ for Senior Leadership (NPQSL)"
  end
end
