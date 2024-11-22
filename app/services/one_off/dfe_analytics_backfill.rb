module OneOff
  class DfeAnalyticsBackfill
    def self.call
      Application.find_each do |a|
        a.senco_in_role    = a.raw_application_data["senco_in_role"]
        a.senco_start_date = a.raw_application_data["senco_start_date"]
        a.on_submission_trn = a.raw_application_data["trn"]

        a.save!
      end
    end
  end
end
