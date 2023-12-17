class Course < ApplicationRecord
  def self.npqeyl
    find_by(identifier: "npq-early-years-leadership")
  end

  def self.ehco
    find_by(identifier: "npq-early-headship-coaching-offer")
  end

  def supports_targeted_delivery_funding?
    !ehco?
  end

  def npqh?
    identifier == NPQ_HEADSHIP
  end

  def npqsl?
    identifier == "npq-senior-leadership"
  end

  def ehco?
    identifier == "npq-early-headship-coaching-offer"
  end

  def eyl?
    identifier == "npq-early-years-leadership"
  end

  def npqltd?
    identifier == "npq-leading-teaching-development"
  end

  def npqlpm?
    identifier == "npq-leading-primary-mathematics"
  end

  NPQ_HEADSHIP = "npq-headship"
  private_constant :NPQ_HEADSHIP
end
