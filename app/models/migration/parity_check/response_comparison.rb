module Migration
  class ParityCheck::ResponseComparison < ApplicationRecord
    before_validation :clear_response_bodies_when_equal

    belongs_to :lead_provider

    validates :lead_provider, presence: true
    validates :request_path, presence: true
    validates :request_method, inclusion: { in: %w[get post put] }
    validates :ecf_response_status_code, inclusion: { in: 100..599 }
    validates :npq_response_status_code, inclusion: { in: 100..599 }
    validates :ecf_response_body, presence: true, if: -> { different? }
    validates :npq_response_body, presence: true, if: -> { different? }
    validates :ecf_response_time_ms, numericality: { greater_than: 0 }
    validates :npq_response_time_ms, numericality: { greater_than: 0 }

    def equal?
      ecf_response_status_code == npq_response_status_code && ecf_response_body == npq_response_body
    end

    def different?
      !equal?
    end

  private

    def clear_response_bodies_when_equal
      return unless equal?

      assign_attributes(ecf_response_body: nil, npq_response_body: nil)
    end
  end
end
