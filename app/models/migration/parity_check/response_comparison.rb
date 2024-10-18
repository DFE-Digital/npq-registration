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

    delegate :name, to: :lead_provider, prefix: true

    scope :with_differences, -> { where("ecf_response_status_code != npq_response_status_code OR ecf_response_body != npq_response_body") }

    class << self
      def by_lead_provider
        includes(:lead_provider).group_by(&:lead_provider_name)
      end

      def response_times_by_path
        select(:request_path, :request_method, :ecf_response_time_ms, :npq_response_time_ms)
          .group_by(&:description)
          .transform_values do |comparisons|
          {
            ecf: {
              avg: comparisons.sum(&:ecf_response_time_ms) / comparisons.size,
              min: comparisons.min_by(&:ecf_response_time_ms).ecf_response_time_ms,
              max: comparisons.max_by(&:ecf_response_time_ms).ecf_response_time_ms,
            },
            npq: {
              avg: comparisons.sum(&:npq_response_time_ms) / comparisons.size,
              min: comparisons.min_by(&:npq_response_time_ms).npq_response_time_ms,
              max: comparisons.max_by(&:npq_response_time_ms).npq_response_time_ms,
            },
          }
        end
      end
    end

    def different?
      ecf_response_status_code != npq_response_status_code || ecf_response_body != npq_response_body
    end

    def description
      "#{request_method.upcase} #{request_path}"
    end

    def npq_slower?
      npq_response_time_ms > ecf_response_time_ms
    end

    def response_body_diff
      Diffy::Diff.new(ecf_response_body, npq_response_body, context: 3)
    end

  private

    def clear_response_bodies_when_equal
      return if different?

      assign_attributes(ecf_response_body: nil, npq_response_body: nil)
    end
  end
end
