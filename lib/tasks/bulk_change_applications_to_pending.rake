# frozen_string_literal: true

namespace :one_off do
  # Bulk change NPQ applications to pending.
  # Accepts a CSV of application (ecf) IDs (without a header row) and a dry run
  # flag. If the dry run flag is true, or not set, the changes will not be performed
  # but the changes that would be made will be logged. Set dry run to false
  # to commit the changes.
  #
  # Example usage (dry run):
  # bundle exec rake 'one_off:bulk_change_to_pending[applications.csv]'
  #
  # Example usage (perform change):
  # bundle exec rake 'one_off:bulk_change_to_pending[applications.csv,false]'
  desc "Change NPQ applications to pending"
  task :bulk_change_to_pending, %i[file dry_run] => :environment do |_task, args|
    logger = Logger.new($stdout)
    csv_file_path = args[:file]
    dry_run = args[:dry_run] != "false"
    unless File.exist?(csv_file_path)
      logger.error "File not found: #{csv_file_path}"
      exit 1
    end

    application_ecf_ids = CSV.read(csv_file_path, headers: false).flatten

    logger.info "Bulk changing #{application_ecf_ids.size} applications to pending#{' (dry run)' if dry_run}..."

    result = OneOff::BulkChangeApplicationsToPending.new(application_ecf_ids:).run!(dry_run:)

    logger.info JSON.pretty_generate(result)
  end
end
