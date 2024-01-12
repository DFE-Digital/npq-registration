module Migration
  class Migrator
    class MigrationInProgressError < RuntimeError; end
    class NoMigrationInProgressError < RuntimeError; end

    attr_reader :result

    def migrate!
      retrieve_prepared_result
      write_reconciliation_metrics!
      cache_orphan_details
      finalise_result!
    end

    class << self
      def prepare_for_migration!
        raise MigrationInProgressError if Migration::Result.in_progress.present?

        Migration::Result.create!
      end
    end

  private

    def retrieve_prepared_result
      @result = Migration::Result.in_progress

      raise NoMigrationInProgressError if result.blank?
    end

    def cache_orphan_details
      result.cache_orphan_report(Migration::OrphanReport.new(users_reconciler), "users")
      result.cache_orphan_report(Migration::OrphanReport.new(applications_reconciler), "applications")
    end

    def write_reconciliation_metrics!
      result.update!(
        users_count: users_reconciler.matches.size,
        orphaned_ecf_users_count: users_reconciler.orphaned_ecf.size,
        orphaned_npq_users_count: users_reconciler.orphaned_npq.size,
        duplicate_users_count: users_reconciler.duplicated.size,
        matched_users_count: users_reconciler.matched.size,
        applications_count: applications_reconciler.matches.size,
        orphaned_ecf_applications_count: applications_reconciler.orphaned_ecf.size,
        orphaned_npq_applications_count: applications_reconciler.orphaned_npq.size,
        duplicate_applications_count: applications_reconciler.duplicated.size,
        matched_applications_count: applications_reconciler.matched.size,
      )
    end

    def finalise_result!
      result.update!(completed_at: Time.zone.now)
    end

    def applications_reconciler
      @applications_reconciler ||= ReconcileApplications.new
    end

    def users_reconciler
      @users_reconciler ||= Migration::ReconcileUsers.new
    end
  end
end
