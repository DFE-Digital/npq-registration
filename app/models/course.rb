class Course < ApplicationRecord
  scope :ehco, -> { where(identifier: "npq-early-headship-coaching-offer") }
  scope :npqeyl, -> { where(identifier: "npq-early-years-leadership") }
  scope :npqltd, -> { where(identifier: "npq-leading-teaching-development") }
  scope :npqh, -> { where(identifier: "npq-headship") }

  def supports_targeted_delivery_funding?
    !ehco?
  end

  def npqh?
    identifier == "npq-headship"
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
end
