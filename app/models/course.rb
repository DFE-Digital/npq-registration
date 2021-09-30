class Course < ApplicationRecord
  def studying_for_headship?
    name == "NPQ for Headship (NPQH)"
  end

  def studying_for_aso?
    name == "Additional Support Offer for new headteachers"
  end
end
