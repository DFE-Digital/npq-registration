module Migration
  class ParityCheck
    class UnsupportedEnvironmentError < RuntimeError; end
    class EndpointsFileNotFoundError < RuntimeError; end
    class NotPreparedError < RuntimeError; end

    attr_reader :endpoints_file_path

    class << self
      def prepare!
        Rails.cache.write(:parity_check_started_at, Time.zone.now)
        Rails.cache.write(:parity_check_completed_at, nil)
        Rails.cache.write(:parity_check_job_count, nil)

        # We want this to be fast, so we're not bothering with callbacks.
        Migration::ParityCheck::ResponseComparison.delete_all
      end

      def running?
        started_at && !completed_at
      end

      def completed?
        completed_at.present?
      end

      def started_at
        Rails.cache.read(:parity_check_started_at)
      end

      def completed_at
        Rails.cache.read(:parity_check_completed_at)
      end

      def finalise!
        Delayed::Job.with_advisory_lock("finalise_parity_check") do
          queued_jobs = Delayed::Job.where("handler LIKE ?", "%ParityCheckComparison%").where("locked_at IS NULL").exists?
          in_progress_job_count = Delayed::Job.where("handler LIKE ?", "%ParityCheckComparison%").where.not("locked_at IS NULL").count

          # All jobs call finalise!, but we only want the last running job
          # to set the completed_at timestamp.
          return if queued_jobs || in_progress_job_count != 1

          Rails.cache.write(:parity_check_completed_at, Time.zone.now)
        end
      end

      def progress
        remaining_jobs_count = Delayed::Job.where("handler LIKE ?", "%ParityCheckComparison%").count
        total_jobs_count = Rails.cache.read(:parity_check_job_count)

        return 0 if total_jobs_count.nil?
        return 100 if total_jobs_count.zero?

        (((total_jobs_count - remaining_jobs_count.to_f) / total_jobs_count) * 100).round(1)
      end
    end

    def initialize(endpoints_file_path: "config/parity_check_endpoints.yml")
      @endpoints_file_path = endpoints_file_path
    end

    def run!
      raise UnsupportedEnvironmentError, "The parity check functionality is disabled for this environment" unless enabled?
      raise NotPreparedError, "You must call prepare! before running the parity check" unless prepared?
      raise EndpointsFileNotFoundError, "Endpoints file not found: #{endpoints_file_path}" unless endpoints_file_exists?

      set_job_count

      lead_providers.each { |lead_provider| queue_endpoints(lead_provider) }
    end

  private

    def prepared?
      self.class.started_at.present?
    end

    def endpoints_file_exists?
      File.exist?(endpoints_file_absolute_path)
    end

    def endpoints_file_absolute_path
      Rails.root.join(endpoints_file_path)
    end

    def set_job_count
      count = lead_providers.size * endpoints.sum { |_, paths| paths.size }

      Rails.cache.write(:parity_check_job_count, count)
    end

    def queue_endpoints(lead_provider)
      endpoints.each do |method, paths|
        paths.each do |path, options|
          ParityCheckComparisonJob.perform_later(lead_provider:, method:, path:, options:)
        end
      end
    end

    def endpoints
      @endpoints ||= YAML.load_file(endpoints_file_absolute_path).with_indifferent_access
    end

    def enabled?
      Rails.application.config.npq_separation[:parity_check][:enabled]
    end

    def lead_providers
      @lead_providers ||= LeadProvider.all
    end
  end
end
