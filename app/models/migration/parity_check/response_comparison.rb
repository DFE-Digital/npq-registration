module Migration
  class ParityCheck::ResponseComparison < ApplicationRecord
    attr_accessor :exclude

    before_validation :format_json_response_bodies, :populate_response_body_ids, :clear_response_bodies_when_equal

    belongs_to :lead_provider

    validates :lead_provider, presence: true
    validates :request_path, presence: true
    validates :page, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
    validates :request_method, inclusion: { in: %w[get post put] }
    validates :ecf_response_status_code, inclusion: { in: 100..599 }
    validates :npq_response_status_code, inclusion: { in: 100..599 }
    validates :ecf_response_body, presence: true, if: -> { different? }
    validates :npq_response_body, presence: true, if: -> { different? }
    validates :ecf_response_time_ms, numericality: { greater_than: 0 }
    validates :npq_response_time_ms, numericality: { greater_than: 0 }

    delegate :name, to: :lead_provider, prefix: true

    scope :matching, lambda { |comparison|
      where(
        lead_provider: comparison.lead_provider,
        request_path: comparison.request_path,
        request_method: comparison.request_method,
      )
      .order(page: :asc)
    }

    class << self
      def by_lead_provider
        includes(:lead_provider)
          .group_by(&:lead_provider_name)
          .transform_values do |comparisons|
            comparisons.group_by(&:description)
          end
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

    def unexpected?
      [ecf_response_status_code, npq_response_status_code].any? { |code| code != 200 }
    end

    def needs_review?
      different? || unexpected?
    end

    def description
      "#{request_method.upcase} #{request_path}"
    end

    def response_body_diff
      @response_body_diff ||= Diffy::Diff.new(ecf_response_body, npq_response_body, context: 3)
    end

  private

    def populate_response_body_ids
      self.ecf_response_body_ids = Array.wrap(ecf_response_body_hash&.dig("data") || []).map { |record| record["id"] }
      self.npq_response_body_ids = Array.wrap(npq_response_body_hash&.dig("data") || []).map { |record| record["id"] }
    end

    def format_json_response_bodies
      self.ecf_response_body = pretty_format(ecf_response_body_hash) if ecf_response_body_hash
      self.npq_response_body = pretty_format(npq_response_body_hash) if npq_response_body_hash
    end

    def pretty_format(hash)
      JSON.pretty_generate(hash)
    end

    def ecf_response_body_hash
      @ecf_response_body_hash ||= deep_remove_keys(JSON.parse(ecf_response_body).deep_sort, exclude)
    rescue JSON::ParserError, TypeError
      nil
    end

    def npq_response_body_hash
      @npq_response_body_hash ||= deep_remove_keys(JSON.parse(npq_response_body).deep_sort, exclude)
    rescue JSON::ParserError, TypeError
      nil
    end

    def clear_response_bodies_when_equal
      return if different?

      assign_attributes(ecf_response_body: nil, npq_response_body: nil)
    end

    def deep_remove_keys(hash, keys_to_remove)
      return hash if keys_to_remove.blank?

      case hash
      when Hash
        hash.each_with_object({}) do |(key, value), result|
          next if key.in?(keys_to_remove)

          result[key] = deep_remove_keys(value, keys_to_remove)
        end
      when Array
        hash.map { |item| deep_remove_keys(item, keys_to_remove) }
      else
        hash
      end
    end
  end
end
