class Course < ApplicationRecord
  def studying_for_headship?
    name == "NPQ for Headship (NPQH)"
  end
end
