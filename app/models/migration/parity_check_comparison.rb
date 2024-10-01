module Migration
  class ParityCheckComparison < ApplicationRecord
    validates :path, presence: true
    validates :method, inclusion: { in: %w[get post put] }
    validates :ecf_status, inclusion: { in: 100..599 }
    validates :npq_status, inclusion: { in: 100..599 }
    validates :ecf_response, presence: true
    validates :npq_response, presence: true
    validates :equal, inclusion: { in: [true, false] }
  end
end
