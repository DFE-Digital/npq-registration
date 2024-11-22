namespace :one_off do
  desc "Backfill application_trn, senco_in_role, senco_start_date"
  task backfill_data_for_dfe_analytics: :environment do
    OneOff::DfeAnalyticsBackfill.call
  end
end
