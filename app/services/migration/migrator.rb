module Migration
  class Migrator
    def migrate!
      write_migration_result!
    end

  private

    def write_migration_result!
      Migration::Result.create!(
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

    def applications_reconciler
      @applications_reconciler ||= ReconcileApplications.new
    end

    def users_reconciler
      @users_reconciler ||= Migration::ReconcileUsers.new
    end
  end
end
